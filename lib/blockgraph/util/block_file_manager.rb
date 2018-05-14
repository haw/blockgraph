module BlockGraph
  module Util
    class BlockFileManager < FileManager

      def initialize
        super
      end

      def insert_header
        node_file << ["uuid", "block_hash", "version", "merkle_root", "time", "bits", "nonce", "size", "height", "tx_num", "input_num", "output_num", "file_num"]
        rel_file << ["block_hash", "previous_block"]
      end

      def open(file_name, mode = "r", **opt)
        super(file_name, mode)
        insert_header if opt[:header]
      end

      def export(nodes, rels)
        open("block_headers", "w", header: true)
        nodes.each{ |node| node_file << node }
        rels.each{ |rel| rel_file << rel }
        close
      end

    end
  end
end