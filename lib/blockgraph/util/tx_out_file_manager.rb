module BlockGraph
  module Util
    class TxOutFileManager < FileManager

      attr_accessor :large_node_file

      def initialize(**opt)
        file_name = opt[:file_name] || "transactions_outputs"
        super(file_name)
        @large_node_file = CSV.open(path(file_name + "_large.csv"), "w", force_quotes: true)
        insert_header if opt[:header]
      end

      def insert_header
        node_file << ["uuid", "value", "n", "script_pubkey"]
        large_node_file << ["uuid", "value", "n", "script_pubkey"]
        rel_file << ["uuid", "transaction"]
      end

      def flush
        node_file.flush
        large_node_file.flush
        rel_file.flush
      end

    end
  end
end