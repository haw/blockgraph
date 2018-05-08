module BlockGraph
  module Util
    class TxFileManager < FileManager

      def initialize(**opt)
        file_name = opt[:file_name] || "transactions"
        super(file_name)
        insert_header if opt[:header]
      end

      def insert_header
        node_file << ["uuid", "txid", "version", "marker", "falg", "lock_time"]
        rel_file << ["txid", "block_hash"]
      end

    end
  end
end