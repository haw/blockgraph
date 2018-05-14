module BlockGraph
  module Util
    class TxOutFileManager < FileManager

      attr_accessor :large_node_file

      def initialize
        super
      end

      def insert_header
        node_file << ["uuid", "value", "n", "script_pubkey"]
        large_node_file << ["uuid", "value", "n", "script_pubkey"]
        rel_file << ["uuid", "transaction"]
      end

      def open(file_name, mode = "r", **opt)
        super(file_name, mode)
        @large_node_file = CSV.open(path(file_name + "_large.csv"), mode, force_quotes: true)
        insert_header if opt[:header]
      end

      def export(nodes, rels)
        open("transactions_outputs", "w", header: true)
        nodes[0].each{ |node| node_file << node }
        nodes[1].each{ |node| large_node_file << node}
        rels.each{ |rel| rel_file << rel}
        close
      end

      def flush
        node_file.flush
        large_node_file.flush
        rel_file.flush
      end

      def close
        node_file.close
        large_node_file.close
        rel_file.close
      end

      def closed?
        node_file.closed? && rel_file.closed? && large_node_file.closed?
      end

    end
  end
end