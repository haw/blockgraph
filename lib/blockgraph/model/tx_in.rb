module BlockGraph
  module Model
    class TxIn < ActiveNodeBase

      property :txid
      property :vout, type: Integer
      property :script_sig
      property :sequence, type: Integer
      property :script_witness
      property :index, type: Integer

      has_one :out, :transaction, type: :transaction, model_class: 'BlockGraph::Model::Transaction'
      has_one :in, :out_point, origin: :spent_input, model_class: 'BlockGraph::Model::TxOut'

      validates :sequence, :presence => true

      after_create :add_out_point

      def self.create_from_tx(tx, n)
        tx_in = new
        unless tx.coinbase?
          tx_in.txid = tx.out_point.txid
          tx_in.vout = tx.out_point.index
        end
        tx_in.script_sig = tx.script_sig.to_hex
        tx_in.script_witness = tx.script_witness.payload unless tx.script_witness.empty?
        tx_in.sequence = tx.sequence
        tx_in.index = n
        tx_in.save!
        tx_in
      end

      def self.builds(txes)
        # Don't save this method.
        # return Array for BlockGraph::Model::TxIn association.
        inputs = []
        txes.each_with_index do |tx, i|
          tx_in = new
          unless tx.coinbase?
            tx_in.txid = tx.out_point.txid
            tx_in.vout = tx.out_point.index
          end
          tx_in.script_sig = tx.script_sig.to_hex
          tx_in.script_witness = tx.script_witness.payload unless tx.script_witness.empty?
          tx_in.sequence = tx.sequence
          tx_in.index = i
          inputs << tx_in
        end
        inputs
      end

      def self.import(file_name)
        puts "tx inputs import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            uuid: row.uuid
                          })
                          ON CREATE SET tx.txid = row.txid, tx.vout = toInteger(row.vout), tx.script_sig = row.script_sig, tx.script_witness = row.script_witness, tx.sequence = toInteger(row.sequence), tx.index = toInteger(row.index), tx.updated_at = timestamp(), tx.created_at = timestamp()
                          ON MATCH SET tx.txid = row.txid, tx.vout = toInteger(row.vout), tx.updated_at = timestamp()
                        ")
        puts "tx inputs relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_rel.csv' AS row WITH row.spent_tx AS spent_id, row.uuid AS uuid
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {uuid: spent_id})
                          MATCH (in:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (in)-[:transaction]->(tx)
                        ")
        puts "outpoint import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row WITH row.uuid AS uuid, row.txid AS txid, toInteger(row.vout) AS vout
                          MATCH (tx:`BlockGraph::Model::Transaction` {txid: txid})<-[:transaction]-(out:`BlockGraph::Model::TxOut` {n: vout})
                          MATCH (in:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (out)-[:out_point]->(in)
                        ")
        puts "tx inputs import end #{Time.current}"
      end

      def self.import_node(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx inputs#{num_str} import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_inputs#{num_str}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            uuid: row.uuid
                          })
                          ON CREATE SET tx.txid = row.txid, tx.vout = toInteger(row.vout), tx.script_sig = row.script_sig, tx.script_witness = row.script_witness, tx.sequence = toInteger(row.sequence), tx.index = toInteger(row.index), tx.updated_at = timestamp(), tx.created_at = timestamp()
                          ON MATCH SET tx.txid = row.txid, tx.vout = toInteger(row.vout), tx.updated_at = timestamp()
                        ")
        puts "tx inputs#{num_str} import end #{Time.current}"
      end

      def self.import_rel(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx inputs#{num_str} relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_inputs#{num_str}_rel.csv' AS row WITH row.spent_tx AS spent_id, row.uuid AS uuid
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {uuid: spent_id})
                          MATCH (in:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (in)-[:transaction]->(tx)
                        ")
        puts "tx inputs#{num_str} outpoint import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_inputs#{num_str}.csv' AS row WITH row.uuid AS uuid, row.txid AS txid, toInteger(row.vout) AS vout
                          MATCH (tx:`BlockGraph::Model::Transaction` {txid: txid})<-[:transaction]-(out:`BlockGraph::Model::TxOut` {n: vout})
                          MATCH (in:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (out)-[:out_point]->(in)
                        ")
        puts "tx inputs#{num_str} relation and outpoint import end #{Time.current}"
      end

      def add_out_point
        return if self.txid.nil? && self.vout.nil?
        tx_out = BlockGraph::Model::TxOut.find_by_outpoint(self.txid, self.vout)
        if tx_out
          self.out_point = tx_out
          save!
        end
      end

      def to_payload(script_sig = self.script_sig, sequence = self.sequence)
        p = self.txid.blank? && self.vout.blank? ? Bitcoin::OutPoint.create_coinbase_outpoint.to_payload : Bitcoin::OutPoint.from_txid(self.txid, self.vout).to_payload
        p << Bitcoin.pack_var_int(script_sig.htb.bytesize)
        p << script_sig.htb << [sequence].pack('V')
        p
      end

      def coinbase?
        self.txid.blank? && self.vout.blank?
      end
    end
  end
end
