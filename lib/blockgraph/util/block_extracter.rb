module BlockGraph
  module Util
    class BlockExtracter < FileManager

      attr_reader :data

      HEADER = ["uuid", "block_hash", "version", "merkle_root", "time", "bits", "nonce", "size", "height", "tx_num", "input_num", "output_num", "file_num", "previous_block"]

      def initialize(data, **opt)
        @data = data
        file_name = opt[:file_name].presence || "block_headers"
        super(file_name, opt)
        file_generate(node_file, HEADER[0...-1])
        file_generate(rel_file, [HEADER[1], HEADER[-1]])
      end

      def export
        data.each do |block|
          uuid = SecureRandom.uuid
          puts "block node csv export begin #{Time.current}"
          CSV.open(path(node_file), "a", force_quotes: true) do |csv|
            csv << [uuid, block.block_hash, block.header.version, block.header.merkle_root, block.header.time, block.header.bits, block.header.nonce,
                    block.size, block.height, block.tx_count, block.input_count, block.output_count, block.file_num]
          end
          puts "block node csv export end #{Time.current}"
          puts "block node relation csv export begin #{Time.current}"
          CSV.open(path(rel_file), "a", force_quotes: true) do |csv|
            csv << [block.block_hash, block.header.prev_hash]
          end
          puts "block node relation csv export end #{Time.current}"
        end
      end

    end
  end
end