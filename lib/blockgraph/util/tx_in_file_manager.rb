module BlockGraph
  module Util
    class TxInFileManager < FileManager

      def initialize(**opt)
        file_name = opt[:file_name] || "transactions_inputs"
        super(file_name)
        insert_header if opt[:header]
      end

      def insert_header
        node_file << ["uuid", "script_sig", "script_witness", "sequence", "vout", "txid"]
        rel_file << ["uuid", "spent_tx"]
      end

    end
  end
end