module BlockGraph
  module Parser
    class ChainIndex

      attr_reader :config
      attr_accessor :block_list
      attr_accessor :old_chain
      attr_accessor :newest_block

      READ_FILE_LIMIT = 4

      def initialize(config)
        @config = config
        @block_list = {}
      end

      def update
        file_num = 0
        file_pos = 0

        latest_block = BlockGraph::Model::BlockHeader.all.order(file_num: :desc, file_pos: :desc).limit(1)[0]

        unless latest_block.blank?
          file_num = latest_block.file_num
          file_pos = latest_block.file_pos + latest_block.size + 8
        end

        max_file_num = max_block_file_num

        file_count = max_file_num - file_num + 1
        file_done = 0
        valid_magic_head = Bitcoin.chain_params.magic_head.htb
        blocks = []

        files = []
        file_count = READ_FILE_LIMIT if file_count > READ_FILE_LIMIT
        file_count.times do |i|
          files << config.path_for_block_file(file_num + i)
        end

        puts "fetch block start. #{file_count} blk files. #{Time.current}"
        Parallel.map(files, in_processes: 4, finish: -> (item, i, result){
          @newest_block = result.last if !result.empty? && i == files.length - 1
          file_done += 1
          result.each do |b|
            @block_list[b.block_hash] = b
          end
          print "\r#{((file_done.to_f / file_count) * 100).to_i}% done fetching block."
        }) do |file|
          File.open(file) do |f|
            first_file = file == files.first
            last_file = file == files.last
            io = StringIO.new(f.read)
            io.pos = file_pos if first_file && file_pos > 0
            until io.eof?
              current_block_pos = io.pos
              magic_head, size = io.read(8).unpack("a4I")
              unless magic_head == valid_magic_head
                break if last_file && current_block_pos > 0
                raise 'magic bytes is mismatch.'
              end
              block = BlockGraph::Parser::BlockInfo.parse_from_raw_data(io, size, to_file_num(file), current_block_pos)
              blocks << block
            end
            blocks
          end
        end
        puts

      end

      # parse loaded Chain Index
      def self.parse_from_neo4j(config, **option)
        puts "parse from neo4j start #{Time.current}"
        chain_index = self.new(config)
        chain_index.parse(BlockGraph::Model::BlockHeader.find_by(block_hash: Bitcoin.chain_params.genesis_block.header.hash), false)
        BlockGraph::Model::BlockHeader.where('(result_blockgraphmodelblockheader)-[:`previous_block`]->()').find_each do |block|
          chain_index.parse(block, !!option[:tx])
        end
        chain_index.old_chain = chain_index.newest_block = chain_index.block_list.values.max{|b1, b2| b1.height.to_i <=> b2.height.to_i}
        chain_index
      end

      def parse(block, with_tx)
        txes = []
        header = Bitcoin::BlockHeader.new(block.version, (block.genesis_block? ? Bitcoin.chain_params.genesis_block.header.prev_hash : block.previous_block.block_hash), block.merkle_root, block.time, block.bits, block.nonce)
        if with_tx
          block.transactions.order(neo_id: :asc).each do |tx|
            txes << Bitcoin::Tx.parse_from_payload(tx.to_payload)
          end
        end
        info = BlockGraph::Parser::BlockInfo.new(header, block.size, txes, block.tx_num, block.input_num, block.output_num, block.file_num, block.file_pos)
        info.height = block.height
        self.block_list[info.block_hash] = info
      end

      def generate_chain(max_block_height)
        chain = []
        max_height = 0
        max_height_block = nil
        block_list.each do |hash, block|
          next if block.blank? || block.height.blank?
          if block.height > max_height
            max_height_block = block
            max_height = block.height
          end
        end

        return chain if max_height_block.nil?

        hash = max_height_block.block_hash

        while hash != Bitcoin.chain_params.genesis_block.header.prev_hash
          block = block_list[hash]
          chain << block
          hash = Bitcoin::BlockHeader.parse_from_payload(block.header.to_payload).prev_hash
        end

        chain.reverse!
        if max_block_height < 0
          return chain[0..(chain.size-1+max_block_height)]
        elsif max_block_height == 0 || max_block_height > chain.size
          return chain
        else
          return chain[0..max_block_height]
        end
      end

      def blocks_to_add
        chain_blocks = generate_chain(0)
        chain_blocks = chain_blocks[(old_chain.height + 1)..-1] if old_chain
        chain_blocks
      end

      def reorg_blocks
        forward_hashes = {}

        block_list.each do |h, b|
          if forward_hashes[b.header.prev_hash]
            forward_hashes[b.header.prev_hash] << h
          else
            forward_hashes[b.header.prev_hash] = [h]
          end
        end

        puts 'calculate block height.'

        genesis_hash = Bitcoin.chain_params.genesis_block.header.hash
        block_list[genesis_hash].height = 0

        queue = [[genesis_hash, 0]]

        until queue.empty?
          block_hash, height = queue.pop
          if forward_hashes[block_hash]
            forward_hashes[block_hash].each do|next_hash|
              block = block_list[next_hash]
              @newest_block = block
              block.height = height + 1
              queue << [block.block_hash, block.height]
            end
          end
        end

        puts "fetched blocks up to #{newest_block.height} height."
      end

      private

      def max_block_file_num(start_file = 0)
        file_num = start_file
        while File.exist?(config.path_for_block_file(file_num))
          file_num += 1
        end
        file_num - 1
      end

      def to_file_num(file_name)
        num = file_name.slice(file_name.index('blk') + 3, 5)
        num.to_i if num
      end

    end
  end
end
