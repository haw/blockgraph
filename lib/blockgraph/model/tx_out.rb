require 'csv'
module BlockGraph
  module Model
    class TxOut < ActiveNodeBase

      property :value, type: Float
      property :n, type: Integer
      property :script_pubkey

      has_one :out, :transaction, type: :transaction, model_class: 'BlockGraph::Model::Transaction'
      has_one :out, :spent_input, type: :out_point, model_class: 'BlockGraph::Model::TxIn'

      validates :value, :presence => true
      validates :n, :presence => true

      def self.create_from_tx(tx, n)
        tx_out = new
        tx_out.value = tx.value
        tx_out.n = n
        if tx.script_pubkey.present?
          tx_out.script_pubkey = tx.script_pubkey.to_hex
        end
        tx_out.save!
        tx_out
      end

      def self.builds(txes)
        # Don't save this method.
        # return Array for BlockGraph::Model::TxOut association.
        txes.map.with_index{|tx, n|
          tx_out = new
          tx_out.value = tx.value
          tx_out.n = n
          if tx.script_pubkey.present?
            tx_out.script_pubkey = tx.script_pubkey.to_hex
          end
          tx_out
        }
      end

      def self.import(file_name)
        puts "tx outputs import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row
                          MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            uuid: row.uuid
                          })
                          ON CREATE SET tx.value = toFloat(row.value), tx.n = toInteger(row.n), tx.script_pubkey = row.script_pubkey, tx.updated_at = timestamp(), tx.created_at = timestamp()
                          ON MATCH SET tx.script_pubkey = row.script_pubkey, tx.updated_at = timestamp()
                        ")
        CSV.foreach(File.expand_path("db/neo4j/test/import/#{file_name}_large.csv", Dir.pwd), headers: true) do |csv|
          self.neo4j_query("MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                            {uuid: '#{csv["uuid"]}'})
                            ON CREATE SET tx.value = toFloat(#{csv["value"]}), tx.n = toInteger(#{csv["n"]}), tx.script_pubkey = '#{csv["script_pubkey"]}', tx.updated_at = timestamp(), tx.created_at = timestamp()
                            ON MATCH SET tx.script_pubkey = '#{csv["script_pubkey"]}', tx.updated_at = timestamp()
                          ")
        end
        puts "tx outputs relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_rel.csv' AS row WITH row.transaction AS tx_id, row.uuid AS uuid
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {uuid: tx_id})
                          MATCH (out:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (out)-[:transaction]->(tx)
                        ")
        puts "tx outputs import end #{Time.current}"
      end

      def self.find_by_outpoint(txid, n)
        tx = BlockGraph::Model::Transaction.find_by(txid: txid)
        if tx
          tx.outputs.each do |o|
            return o if o.n == n
          end
        end
      end

      def to_payload
        s = self.script_pubkey.htb
        [self.value].pack('Q') << Bitcoin.pack_var_int(s.length) << s
      end

    end
  end
end