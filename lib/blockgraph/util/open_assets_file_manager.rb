module BlockGraph
  module Util
    class OpenAssetsFileManager < FileManager

      def initialize
        super
      end

      def insert_header
        rel_file << ["tx_out_uuid", "asset_id"]
      end

      def open(file_name, mode = "r", **opt)
        @rel_file = CSV.open(path(file_name + "_rel.csv"), mode, force_quotes: true)
        insert_header if opt[:header]
      end

      def close
        rel_file.close
      end

      def closed?
        rel_file.closed?
      end

      def export(rels)
        open("open_assets", "w", header: true)
        rels.each{ |rel| rel_file << rel}
        close
      end

      def to_csv(txs)
        csv = []
        total = txs.size
        puts "data format begin #{Time.current}"
        txs.each_with_index do |tx, i|
          btc_tx = Bitcoin::Tx.parse_from_payload(tx.to_payload)
          outputs = BlockGraph::OpenAssets::Util.get_colored_outputs(btc_tx)
          outputs.each_with_index do |tx_out, n|
            csv << [tx.outputs[n].uuid, tx_out.asset_id]
          end
          print "\rdata formated #{sprintf("%3.1f", ((i+1) / total.to_f) * 100)}%"
        end
        puts
        puts "data format end #{Time.current}"
        csv
      end

    end
  end
end
