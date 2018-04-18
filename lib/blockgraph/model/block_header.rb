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

      def self.create_from_blocks(block)
        bh = BlockHeader.new
        bh.block_hash = block.block_hash
        bh.version = block.header.version
        bh.merkle_root = block.header.merkle_root
        bh.time = block.header.time
        bh.bits = block.header.bits
        bh.nonce = block.header.nonce
        bh.size = block.size
        bh.height = block.height
        bh.tx_num = block.tx_count
        bh.input_num = block.input_count
        bh.output_num = block.output_count
        bh.file_num = block.file_num
        bh.previous_block = self.find_by(block_hash: block.header.prev_hash)
        unless bh.genesis_block?
          bh.transactions = BlockGraph::Model::Transaction.builds(block.transactions)
        end
        bh.save!
      end

      def genesis_block?
        Bitcoin.chain_params.genesis_block.header.hash == self.block_hash
      end

      def self.import(file_name)
        puts "block import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row
                          MERGE (b:`BlockGraph::Model::BlockHeader`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            block_hash: row.block_hash, version: row.version, merkle_root: row.merkle_root, time: row.time,
                            bits: row.bits, nonce: row.nonce, size: row.size, height: row.height, tx_num: row.tx_num, input_num: row.input_num,
                            output_num: row.output_num, file_num: row.file_num
                          })
                          ON CREATE SET b.uuid = row.uuid, b.created_at = timestamp()
                          SET b.updated_at = timestamp()
                        ")
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_rel.csv' AS row
                          MATCH (b:`BlockGraph::Model::BlockHeader` {block_hash: row.block_hash}), (p:`BlockGraph::Model::BlockHeader` {block_hash: row.previous_block})
                          MERGE (b)-[:previous_block]->(p)
                        ")
        puts "block import end #{Time.current}"
      end

    end
  end
end
