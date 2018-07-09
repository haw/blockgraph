require 'csv'
module BlockGraph
  module Model
    class TxOut < ActiveNodeBase

      property :value, type: Float
      property :n, type: Integer
      property :script_pubkey

      property :asset_quantity, type: Integer
      property :oa_output_type, type: Integer

      has_one :out, :transaction, type: :transaction, model_class: 'BlockGraph::Model::Transaction'
      has_one :out, :spent_input, type: :out_point, model_class: 'BlockGraph::Model::TxIn'
      has_one :out, :asset_id, type: :asset_id, model_class: 'BlockGraph::Model::AssetId'

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

      def apply_oa_attributes(oa_out)
        self.asset_quantity = oa_out.asset_quantity
        self.asset_id = oa_out.asset_id.nil? ? nil : AssetId.find_or_create(oa_out.asset_id)
        if self.asset_id.nil? && oa_out.oa_output_type != BlockGraph::Constants::OutputType::MARKER_OUTPUT
          self.oa_output_type = BlockGraph::Constants::OutputType.output_type_label(BlockGraph::Constants::OutputType::UNCOLORED)
        else
          self.oa_output_type = BlockGraph::Constants::OutputType.output_type_label(oa_out.oa_output_type)
        end
        save!
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
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///#{file_name}.csv' AS row WITH row.value AS value, row.n AS n,
                          row.script_pubkey AS script_pubkey, row.asset_quantity AS asset_quantity, row.oa_output_type AS output_type
                          MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            uuid: row.uuid
                          })
                          ON CREATE SET tx.value = toFloat(value), tx.n = toInteger(n), tx.script_pubkey = script_pubkey, tx.asset_quantity = toInteger(asset_quantity), tx.oa_output_type = toInteger(output_type), tx.updated_at = timestamp(), tx.created_at = timestamp()
                          ON MATCH SET tx.value = toFloat(value), tx.n = toInteger(n), tx.script_pubkey = script_pubkey, tx.asset_quantity = toInteger(asset_quantity), tx.oa_output_type = toInteger(output_type), tx.updated_at = timestamp()
                        ")
        CSV.foreach(File.join(self.neo4j_query('CALL dbms.listConfig() yield name,value WHERE name=~"dbms.directories.import" RETURN value').rows.first, "#{file_name}_large.csv"), headers: true) do |csv|
          self.neo4j_query("MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                            {uuid: '#{csv["uuid"]}'})
                            ON CREATE SET tx.value = toFloat(#{csv["value"]}), tx.n = toInteger(#{csv["n"]}), tx.script_pubkey = #{csv["script_pubkey"]}, tx.asset_quantity = toInteger(#{csv["asset_quantity"]}), tx.oa_output_type = toInteger(#{csv["output_type"]}), tx.updated_at = timestamp(), tx.created_at = timestamp()
                            ON MATCH SET tx.value = toFloat(#{csv["value"]}), tx.n = toInteger(#{csv["n"]}), tx.script_pubkey = '#{csv["script_pubkey"]}', tx.asset_quantity = toInteger(#{csv["asset_quantity"]}), tx.oa_output_type = toInteger(#{csv["output_type"]}) tx.updated_at = timestamp()
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

      def self.import_node(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx outputs#{num_str} import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_outputs#{num_str}.csv' AS row WITH row.uuid AS uuid, row.value AS value,
                          row.n AS n, row.script_pubkey AS script_pubkey, row.asset_quantity AS asset_quantity, row.oa_output_type AS output_type
                          MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                          {
                            uuid: uuid
                          })
                          ON CREATE SET tx.value = toFloat(value), tx.n = toInteger(n), tx.script_pubkey = script_pubkey, tx.asset_quantity = asset_quantity, tx.oa_output_type = toInteger(output_type), tx.updated_at = timestamp(), tx.created_at = timestamp()
                          ON MATCH SET tx.value = toFloat(value), tx.n = toInteger(n), tx.script_pubkey = script_pubkey, tx.asset_quantity = asset_quantity, tx.oa_output_type = toInteger(output_type), tx.updated_at = timestamp()
                        ")
        CSV.foreach(File.join(self.neo4j_query('CALL dbms.listConfig() yield name,value WHERE name=~"dbms.directories.import" RETURN value').rows.first, "tx_outputs#{num_str}_large.csv"), headers: true) do |csv|
          self.neo4j_query("MERGE (tx:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase`
                            {uuid: '#{csv["uuid"]}'})
                            ON CREATE SET tx.value = toFloat(#{csv["value"]}), tx.n = toInteger(#{csv["n"]}), tx.script_pubkey = #{csv["script_pubkey"]}, tx.asset_quantity = #{csv["asset_quantity"]}, tx.oa_output_type = toInteger(#{csv["output_type"]}), tx.updated_at = timestamp(), tx.created_at = timestamp()
                            ON MATCH SET tx.value = toFloat(#{csv["value"]}), tx.n = toInteger(#{csv["n"]}), tx.script_pubkey = #{csv["script_pubkey"]}, tx.asset_quantity = #{csv["asset_quantity"]}, tx.oa_output_type = toInteger(#{csv["output_type"]}), tx.updated_at = timestamp()
                          ")
        end
        puts "tx outputs#{num_str} import end #{Time.current}"
      end

      def self.import_rel(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx outputs#{num_str} relation import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_outputs#{num_str}_rel.csv' AS row WITH row.transaction AS tx_id, row.uuid AS uuid
                          MATCH (tx:`BlockGraph::Model::Transaction`:`BlockGraph::Model::ActiveNodeBase` {uuid: tx_id})
                          MATCH (out:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (out)-[:transaction]->(tx)
                        ")
        puts "tx outputs#{num_str} relation import end #{Time.current}"
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

      def output_type
        script = Bitcoin::Script.parse_from_payload(self.script_pubkey.htb)
        script.type
      end

      def addresses
        script = Bitcoin::Script.parse_from_payload(self.script_pubkey.htb)
        {address: script.addresses}
      end
    end
  end
end
