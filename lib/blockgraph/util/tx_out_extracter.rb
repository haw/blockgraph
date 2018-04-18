module BlockGraph
  module Util
    class TxOutExtracter < FileManager

      attr_accessor :data
      attr_accessor :tx_uuid

      HEADER = ["uuid", "value", "n", "script_pubkey", "transaction", "spent_input"]

      # optional initial values
      # params[:data] set a Bitcoin::Tx class
      # params[:file_name] set a file name of String class that exclude file extension.
      def initialize(**opt)
        @data = opt[:data] || nil
        file_name = opt[:file_name].presence || "transactions_outputs"
        super(file_name, opt)
        file_generate(node_file, HEADER[0..3])
        file_generate(rel_file, [HEADER[0], HEADER[4]])

      end

      def export
        puts "transaction output csv export begin #{Time.current}"
        data.outputs.each_with_index do |tx_out, n|
          uuid = SecureRandom.uuid
          puts "transaction output node csv export begin #{Time.current}"
          CSV.open(path(node_file), "a", force_quotes: true) do |csv|
            csv << [uuid, tx_out.value, n, tx_out.script_pubkey.present? ? tx_out.script_pubkey.to_hex : '']
          end
          puts "transaction output node csv export end #{Time.current}"
          puts "transaction output node relation csv export begin #{Time.current}"
          CSV.open(path(rel_file), "a", force_quotes: true) do |csv|
            csv << [uuid, tx_uuid]
          end
          puts "transaction output node relation csv export end #{Time.current}"
        end
      end

    end
  end
end