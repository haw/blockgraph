module BlockGraph
  module Util
    class OpenAssetsFileManager < FileManager

      def initialize
        super
      end

      def insert_header
        node_file << ["tx_out_uuid", "asset_quantity", "oa_output_type"]
        rel_file << ["tx_out_uuid", "asset_id"]
      end

      def open(file_name, mode = "r", **opt)
        @node_file = CSV.open(path(file_name + ".csv"), mode, force_quotes: true)
        @rel_file = CSV.open(path(file_name + "_rel.csv"), mode, force_quotes: true)
        insert_header if opt[:header]
      end

      def close
        node_file.close
        rel_file.close
      end

      def closed?
        node_file.closed? && rel_file.closed?
      end

      def export(nodes, rels)
        open("open_assets", "w", header: true)
        nodes.each{|node| node_file << node}
        rels.each{ |rel| rel_file << rel}
        close
      end

      def to_csv(txs)
        nodes = []
        rels = []
        total = txs.size
        puts "data format begin #{Time.current}"
        txs.each_with_index do |tx, i|
          tx_outs = tx.outputs.order(n: :asc)
          btc_tx = Bitcoin::Tx.parse_from_payload(tx.to_payload)
          outputs = BlockGraph::OpenAssets::Util.get_colored_outputs(btc_tx)
          outputs.each_with_index do |tx_out, n|
            nodes << [tx_outs[n].uuid, tx_out.asset_quantity, tx_out.oa_output_type]
            rels << [tx_outs[n].uuid, tx_out.asset_id]
          end
          print "\rdata formated #{sprintf("%3.1f", ((i+1) / total.to_f) * 100)}%"
        end
        puts
        puts "data format end #{Time.current}"
        [nodes, rels]
      end

    end
  end
end
