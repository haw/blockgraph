module BlockGraph
  module Model
    class Transaction < ActiveNodeBase

      property :txid
      property :version, type: Integer
      property :marker, type: Integer
      property :flag, type: Integer
      property :lock_time, type: Integer
      property :index, type: Integer

      has_one :out, :block, type: :block, model_class: 'BlockGraph::Model::BlockHeader'
      has_many :in, :inputs, origin: :transaction, model_class: 'BlockGraph::Model::TxIn', dependent: :destroy
      has_many :in, :outputs, origin: :transaction, model_class: 'BlockGraph::Model::TxOut', dependent: :destroy

      validates :txid, :presence => true
      validates :version, :presence => true
      validates :lock_time, :presence => true

      scope :with_txid, ->(txid){where(txid: txid)}

      MARKER = 0x00
      FLAG = 0x01

      def self.create_from_tx(tx, idx)
        transaction = new
        transaction.txid = tx.txid
        transaction.version = tx.version
        transaction.marker = tx.marker
        transaction.flag = tx.flag
        transaction.lock_time = tx.lock_time
        transaction.index = idx
        tx.inputs.each_with_index do |i, n|
          transaction.inputs << BlockGraph::Model::TxIn.create_from_tx(i, n)
        end
        tx.outputs.each_with_index do |o, n|
          transaction.outputs << BlockGraph::Model::TxOut.create_from_tx(o, n)
        end
        transaction.save!
        transaction
      end

      def self.builds(txs)
        # Don't save this method.
        # return Array for BlockGraph::Model::Transaction association.
        ret = []
        txs.each_with_index do |tx|
          transaction = new
          transaction.txid = tx.txid
          transaction.version = tx.version
          transaction.marker = tx.marker
          transaction.flag = tx.flag
          transaction.lock_time = tx.lock_time
          transaction.inputs = BlockGraph::Model::TxIn.builds(tx.inputs)
          transaction.outputs = BlockGraph::Model::TxOut.builds(tx.outputs)
          ret << transaction
        end
        ret
      end

      def self.import(file_name)
        puts "transaction import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            txid: row.txid
                          })
                          ON CREATE SET tx.uuid = row.uuid, tx.created_at = timestamp(), tx.version = toInteger(row.version), tx.lock_time = toInteger(row.lock_time), tx.marker = toInteger(row.marker), tx.flag = toInteger(row.flag), tx.index = toInteger(row.index), tx.updated_at = timestamp()
                          ON MATCH SET tx.marker = toInteger(row.marker), tx.flag = toInteger(row.flag), tx.updated_at = timestamp()
                        ")
        puts "transaction relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_rel.csv' AS row WITH row.block_hash AS block_hash, row.txid AS txid
                          MATCH (b:`BlockGraph::Model::BlockHeader`:`BlockGraph::Model::ActiveNodeBase` {block_hash: block_hash})
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {txid: txid})
                          MERGE (tx)-[:block]->(b)
                        ")
        BlockGraph::Model::TxOut.import(file_name[0...(file_name.index("tx") + 2)] + "_outputs" + file_name[(file_name.index("tx") + 2)..-1])
        BlockGraph::Model::TxIn.import(file_name[0...(file_name.index("tx") + 2)] + "_inputs" + file_name[(file_name.index("tx") + 2)..-1])
        puts "transaction import end #{Time.current}"
      end

      def self.import_node(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx#{num_str} import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx#{num_str}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            txid: row.txid
                          })
                          ON CREATE SET tx.uuid = row.uuid, tx.created_at = timestamp(), tx.version = toInteger(row.version), tx.lock_time = toInteger(row.lock_time), tx.marker = toInteger(row.marker), tx.flag = toInteger(row.flag), tx.index = toInteger(row.index), tx.updated_at = timestamp()
                          ON MATCH SET tx.marker = toInteger(row.marker), tx.flag = toInteger(row.flag), tx.updated_at = timestamp()
                        ")
        puts "tx#{num_str} import end #{Time.current}"
      end

      def self.import_rel(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx#{num_str} relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx#{num_str}_rel.csv' AS row WITH row.block_hash AS block_hash, row.txid AS txid
                          MATCH (b:`BlockGraph::Model::BlockHeader`:`BlockGraph::Model::ActiveNodeBase` {block_hash: block_hash})
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {txid: txid})
                          MERGE (tx)-[:block]->(b)
                        ")
        puts "tx#{num_str} relation import end #{Time.current}"
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
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.order(index: :asc).map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.order(n: :asc).map(&:to_payload).join
        buf << [self.lock_time].pack('V')
        buf
      end

      # serialize tx with segwit tx format
      # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki
      def serialize_witness_format
        buf = [self.version, MARKER, FLAG].pack('Vcc')
        buf << Bitcoin.pack_var_int(self.inputs.length) << self.inputs.order(index: :asc).map(&:to_payload).join
        buf << Bitcoin.pack_var_int(self.outputs.length) << self.outputs.order(n: :asc).map(&:to_payload).join
        buf << witness_payload << [self.lock_time].pack('V')
        buf
      end

      def witness_payload
        self.inputs.map { |i| Bitcoin::ScriptWitness.new(i.script_witness.split(' ')).to_payload }.join
      end

      def openassets_tx?
        return true unless self.outputs.asset_id.blank?
        false
      end

      def coinbase_tx?
        self.inputs.length == 1 && self.inputs.order(index: :asc)[0].coinbase?
      end

    end
  end
end
