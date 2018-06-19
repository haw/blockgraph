module BlockGraph
  module Model
    class AssetId < ActiveNodeBase
      property :asset_id

      has_many :in, :outputs, origin: :asset_id, model_class: 'BlockGraph::Model::TxOut'

      validates :asset_id, presence: true

      scope :with_asset_id, ->(asset_id){where(asset_id: asset_id)}

      def self.find_or_create(asset_id)
        a = with_asset_id(asset_id).first
        unless a
          a = new
          a.asset_id = asset_id
          a.save!
        end
        a
      end

      def self.import_rel(num)
        num_str = num.is_a?(Integer) ? num.to_s.rjust(5, '0') : num
        puts "tx outputs#{num_str} assets import begin #{Time.current}"
        self.neo4j_query("USING PERIODIC COMMIT LOAD CSV WITH HEADERS FROM 'file:///tx_outputs#{num_str}_rel.csv' AS row WITH row.uuid AS uuid, row.asset_id AS asset_id
                          WHERE NOT asset_id = ''
                          MATCH (out:`BlockGraph::Model::TxOut`:`BlockGraph::Model::ActiveNodeBase` {uuid: uuid})
                          MERGE (asset:`BlockGraph::Model::AssetId`:`BlockGraph::Model::ActiveNodeBase` {asset_id: asset_id})
                          MERGE (out)-[:asset_id]->(asset)
                        ")
        puts "tx outputs#{num_str} assets import end #{Time.current}"
      end

      def issuance_txs
        outputs.select{|o| o.oa_output_type == 'issuance'}.map(&:transaction)
            .uniq{|tx| tx.txid}.sort{|a, b| b.block.time <=> a.block.time}
      end
    end
  end
end
