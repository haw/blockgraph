module BlockGraph
  module OpenAssets
    module Util

      class Extractor

        attr_reader :oa

        def initialize
          @oa = BlockGraph::Util::OpenAssetsFileManager.new
        end

        def export_asset_ids(txs)
          csv = oa.to_csv(txs)
          puts "export begin #{Time.current}"
          oa.export(csv)
          puts "export end #{Time.current}"
        end

      end

    end
  end
end