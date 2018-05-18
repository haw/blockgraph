module BlockGraph
  module Util
    class TxFileManager < FileManager

      def initialize
        super
      end

      def insert_header
        node_file << ["uuid", "txid", "version", "marker", "falg", "lock_time"]
        rel_file << ["txid", "block_hash"]
      end

      def open(file_name, mode = "r", **opt)
        super(file_name, mode)
        insert_header if opt[:header]
      end

      def export(nodes, rels)
        open(file_name_with_num("tx"), "w", header: true)
        nodes.each{ |node| node_file << node }
        rels.each{ |rel| rel_file << rel }
        close
      end

    end
  end
end