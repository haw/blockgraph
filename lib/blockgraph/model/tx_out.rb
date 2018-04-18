module BlockGraph
  module Model
    class TxOut < ActiveNodeBase

      property :value
      property :n, type: Integer
      property :script_pubkey

      has_one :out, :transaction, type: :transaction, model_class: 'BlockGraph::Model::Transaction'
      has_one :out, :out_point, type: :spent_input, model_class: 'BlockGraph::Model::TxIn'

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
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_outputs.csv' AS row
                          MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            value: row.value, n: row.n
                          })
                          ON CREATE SET tx.uuid = row.uuid, tx.created_at = timestamp()
                          SET tx.script_pubkey = row.script_pubkey, tx.updated_at = timestamp()
                        ")
        self.neo4j_query("USING PERIODIC COMMIT 10000 LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_outputs_rel.csv' AS row
                          MATCH (tx:`BlockGraph::Model::Transaction` {uuid: row.transaction}), (out:`BlockGraph::Model::TxOut` {uuid: row.uuid})
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