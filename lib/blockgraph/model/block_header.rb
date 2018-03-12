module BlockGraph
  module Model
    class BlockHeader < ActiveNodeBase

      property :block_hash
      property :version, type: Integer
      property :prev_id
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
      property :created_at
      property :updated_at

      # has_many :in, :transactions, origin: :block, model_class: 'BlockGraph::Model::Transaction', dependent: :destroy
      has_one :out, :previous_block, type: :previous_block, model_class: 'BlockGraph::Model::BlockHeader'

      validates :block_hash, :presence => true
      validates :height, :presence => true

      after_create :chain_previous_block

      scope :latest, -> {order(height: 'DESC')}
      scope :with_height, -> (height){where(height: height)}

      def self.create_from_blocks(blocks)
        prev_uuid = nil
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
          block.prev_id = prev_uuid
          block.file_num = b.file_num
          block.save!
          prev_uuid = block.uuid
          print "\r#{(((i + 1) / blocks.size.to_f) * 100).to_i}% completed."
        end
        puts
      end

      def genesis_block?
        Bitcoin.chain_params.genesis_block.header.hash == self.block_hash
      end

      private

      def chain_previous_block
        unless self.prev_id.nil?
          self.previous_block = BlockHeader.where(uuid: self.prev_id).first
          save!
        end
      end

    end
  end
end