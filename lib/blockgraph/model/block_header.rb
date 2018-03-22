module BlockGraph
  module Model
    class BlockHeader < ActiveNodeBase

      property :block_hash
      property :version, type: Integer
      property :merkle_root
      property :time, type: Integer
      property :bits
      property :nonce, type: Integer
      property :height, type: Integer
      property :file_num, type: Integer
      property :size, type: Integer
      property :tx_num, type: Integer
      property :input_num, type: Integer
      property :output_num, type: Integer

      has_many :in, :transactions, origin: :block, model_class: 'BlockGraph::Model::Transaction', dependent: :destroy
      has_one :out, :previous_block, type: :previous_block, model_class: 'BlockGraph::Model::BlockHeader'

      validates :block_hash, :presence => true
      validates :height, :presence => true

      scope :latest, -> {order(height: 'DESC')}
      scope :oldest, -> {order(height: :asc)}
      scope :with_height, -> (height){where(height: height)}

      def self.create_from_blocks(blocks)
        prev = nil
        blocks.each_with_index do |(h, b), i|
          block = BlockHeader.new
          block.block_hash = b.block_hash
          block.version = b.header.version
          block.merkle_root = b.header.merkle_root
          block.time = b.header.time
          block.bits = b.header.bits
          block.nonce = b.header.nonce
          block.size = b.size
          block.height = b.height
          block.tx_num = b.tx_count
          block.input_num = b.input_count
          block.output_num = b.output_count
          block.file_num = b.file_num
          block.previous_block = prev
          block.save!
          unless block.genesis_block?
            b.transactions.each do |tx|
              block.transactions << BlockGraph::Model::Transaction.create_from_tx(tx)
            end
          end
          block.save!
          prev = block
          print "\r#{(((i + 1) / blocks.size.to_f) * 100).to_i}% completed."
        end
        puts
      end

      def genesis_block?
        Bitcoin.chain_params.genesis_block.header.hash == self.block_hash
      end

    end
  end
end
