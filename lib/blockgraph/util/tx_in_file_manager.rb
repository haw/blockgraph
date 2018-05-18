module BlockGraph
  module Util
    class TxInFileManager < FileManager

      def initialize
        super
      end

      def insert_header
        node_file << ["uuid", "script_sig", "script_witness", "sequence", "vout", "txid"]
        rel_file << ["uuid", "spent_tx"]
      end

      def open(file_name, mode = "r", **opt)
        super(file_name, mode)
        insert_header if opt[:header]
      end

      def export(nodes, rels)
        open(file_name_with_num("tx_inputs"), "w", header: true)
        nodes.each{ |node| node_file << node }
        rels.each{ |rel| rel_file << rel }
        close
      end

    end
  end
end