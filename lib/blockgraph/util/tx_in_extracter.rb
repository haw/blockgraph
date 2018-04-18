module BlockGraph
  module Util
    class TxInExtracter < FileManager

      attr_accessor :data
      attr_accessor :tx_uuid

      HEADER = ["uuid", "script_sig", "script_witness", "sequence", "vout", "txid", "spent_tx"]

      # optional initial values
      # params[:data] set a Bitcoin::Tx class
      # params[:file_name] set a file name of String class that exclude file extension.
      def initialize(**opt)
        @data = opt[:data] || nil
        file_name = opt[:file_name].presence || "transactions_inputs"
        super(file_name, opt)
        file_generate(node_file, HEADER[0...-1])
        file_generate(rel_file, [HEADER[0], HEADER[-1]])
      end

      def export
        puts "transaction input csv export begin #{Time.current}"
        data.inputs.each do |tx_in|
          uuid = SecureRandom.uuid
          puts "transaction input node csv export begin #{Time.current}"
          CSV.open(path(node_file), "a", force_quotes: true) do |csv|
            csv << [uuid, tx_in.script_sig, tx_in.script_witness, tx_in.sequence, tx_in.coinbase? ? '' : tx_in.out_point.index, tx_in.coinbase? ? '' : tx_in.out_point.hash]
          end
          puts "transaction input node csv export end #{Time.current}"
          puts "transaction input node relation csv export begin #{Time.current}"
          CSV.open(path(rel_file), "a", force_quotes: true) do |csv|
            csv << [uuid, tx_uuid]
          end
          puts "transaction input node relation csv export end #{Time.current}"
        end
        puts "transaction input csv export end #{Time.current}"
      end

    end
  end
end