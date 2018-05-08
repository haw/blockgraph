module BlockGraph
  module Model
    class TxIn < ActiveNodeBase

      property :txid
      property :vout
      property :script_sig
      property :sequence
      property :script_witness

      has_one :out, :transaction, type: :transaction, model_class: 'BlockGraph::Model::Transaction'
      has_one :in, :out_point, origin: :out_point, model_class: 'BlockGraph::Model::TxOut'

      validates :sequence, :presence => true

      after_create :add_out_point

      def self.create_from_tx(tx)
        tx_in = new
        unless tx.coinbase?
          tx_in.txid = tx.out_point.hash
          tx_in.vout = tx.out_point.index
        end
        tx_in.script_sig = tx.script_sig.to_hex
        tx_in.script_witness = tx.script_witness.payload unless tx.script_witness.empty?
        tx_in.sequence = tx.sequence
        tx_in.save!
        tx_in
      end

      def self.builds(txes)
        # Don't save this method.
        # return Array for BlockGraph::Model::TxIn association.
        txes.map{|tx|
          tx_in = new
          unless tx.coinbase?
            tx_in.txid = tx.out_point.hash
            tx_in.vout = tx.out_point.index
          end
          tx_in.script_sig = tx.script_sig.to_hex
          tx_in.script_witness = tx.script_witness.payload unless tx.script_witness.empty?
          tx_in.sequence = tx.sequence
          tx_in
        }
      end

      def self.import(file_name)
        puts "tx inputs import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_inputs.csv' AS row
                          CREATE (tx:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            script_sig: row.script_sig, script_witness: row.script_witness, sequence: row.sequence, uuid: row.uuid, created_at: timestamp()
                          })
                          SET tx.txid = row.txid, tx.vout = row.vout, tx.updated_at = timestamp()
                        ")
        puts "tx inputs relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}_inputs_rel.csv' AS row WITH row.spent_tx AS spent_id, row.uuid AS uuid
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {uuid: spent_id}), (in:`BlockGraph::Model::TxIn`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (in)-[:transaction]->(tx)
                        ")
        puts "tx inputs import end #{Time.current}"
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
        p = self.txid.nil? && self.vout.nil? ? Bitcoin::OutPoint.create_coinbase_outpoint.to_payload : Bitcoin::OutPoint.new(self.txid, self.vout).to_payload
        p << Bitcoin.pack_var_int(script_sig.htb.bytesize)
        p << script_sig.htb << [sequence].pack('V')
        p
      end
    end
  end
end