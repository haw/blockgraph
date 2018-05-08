module BlockGraph
  module Util
    class BlockFileManager < FileManager

      def initialize(**opt)
        file_name = opt[:file_name] || "block_headers"
        super(file_name)
        insert_header if opt[:header]
      end

      def insert_header
        node_file << ["uuid", "block_hash", "version", "merkle_root", "time", "bits", "nonce", "size", "height", "tx_num", "input_num", "output_num", "file_num"]
        rel_file << ["block_hash", "previous_block"]
      end

    end
  end
end