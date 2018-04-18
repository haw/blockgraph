module BlockGraph
  module Model
    class Transaction < ActiveNodeBase

      property :txid
      property :version, type: Integer
      property :marker, type: Integer
      property :flag, type: Integer
      property :lock_time

      has_one :out, :block, type: :block, model_class: 'BlockGraph::Model::BlockHeader'
      has_many :in, :inputs, origin: :transaction, model_class: 'BlockGraph::Model::TxIn', dependent: :destroy
      has_many :in, :outputs, origin: :transaction, model_class: 'BlockGraph::Model::TxOut', dependent: :destroy

      validates :txid, :presence => true
      validates :version, :presence => true
      validates :lock_time, :presence => true

      scope :with_txid, ->(txid){where(txid: txid)}

      MARKER = 0x00
      FLAG = 0x01

      def self.create_from_tx(tx)
        transaction = new
        transaction.txid = tx.txid
        transaction.version = tx.version
        transaction.marker = tx.marker
        transaction.flag = tx.flag
        transaction.lock_time = tx.lock_time
        tx.inputs.each do |i|
          transaction.inputs << BlockGraph::Model::TxIn.create_from_tx(i)
        end
        tx.outputs.each_with_index do |o, n|
          transaction.outputs << BlockGraph::Model::TxOut.create_from_tx(o, n)
        end
        transaction.save!
        transaction
      end

      def self.builds(txes)
        # Don't save this method.
        # return Array for BlockGraph::Model::Transaction association.
        txes.map{|tx|
          transaction = new
          transaction.txid = tx.txid
          transaction.version = tx.version
          transaction.marker = tx.marker
          transaction.flag = tx.flag
          transaction.lock_time = tx.lock_time
          transaction.inputs = BlockGraph::Model::TxIn.builds(tx.inputs)
          transaction.outputs = BlockGraph::Model::TxOut.builds(tx.outputs)
          transaction
        }
      end

      def self.import(file_name)
        puts "transaction import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            txid: row.txid, version: toInt(row.version), lock_time: row.lock_time
                          })
                          ON CREATE SET tx.uuid = row.uuid, tx.created_at = timestamp()
                          SET tx.marker = toInt(row.marker), tx.flag = toInt(row.flag), tx.updated_at = timestamp()
                        ")
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_rel.csv' AS row
                          MATCH (b:`BlockGraph::Model::BlockHeader` {block_hash: row.block_hash}), (tx:`BlockGraph::Model::Transaction` {txid: row.txid})
                          MERGE (tx)-[:block]->(b)
                        ")
        BlockGraph::Model::TxIn.import(file_name)
        BlockGraph::Model::TxOut.import(file_name)
        puts "transaction import end #{Time.current}"
      end

      def to_payload
        witness? ? serialize_witness_format : serialize_old_format
      end

      def witness?
        inputs = self.inputs.to_a
        !inputs.find { |i| !i.script_witness.nil? }.nil?
      end

      # serialize tx with old tx format
      def serialize_old_format
        buf = [self.version].pack('V')
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.order(vout: :asc).map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.order(n: :asc).map(&:to_payload).join
        buf << [self.lock_time].pack('V')
        buf
      end

      # serialize tx with segwit tx format
      # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki
      def serialize_witness_format
        buf = [self.version, MARKER, FLAG].pack('Vcc')
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.map(&:to_payload).join
        buf << witness_payload << [self.lock_time].pack('V')
        buf
      end

      def witness_payload
        self.inputs.map { |i| i.script_witness.to_payload }.join
      end

    end
  end
end