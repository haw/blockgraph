module BlockGraph
  module Util
    class TxExtracter < FileManager

      attr_reader :data

      HEADER = ["uuid", "txid", "version", "marker", "falg", "lock_time", "block_hash"]
      INPUTS_HEADER = []
      OUTPUTS_HEADER = []

      def initialize(data, **opt)
        @data = data
        @file_name = opt[:file_name].presence || "transactions"
        super(@file_name, opt)
        file_generate(node_file, HEADER[0...-1])
        file_generate(rel_file, [HEADER[-1], HEADER[1]])
      end

      def export
        tx_in_extracter = BlockGraph::Util::TxInExtracter.new({file_name: (@file_name + '_inputs')})
        tx_out_extracter = BlockGraph::Util::TxOutExtracter.new({file_name: (@file_name + '_outputs')})
        data.each do |block|
          block.transactions.each do |tx|
            uuid = SecureRandom.uuid
            puts "transaction node csv export begin #{Time.current}"
            CSV.open(path(node_file), "a", force_quotes: true) do |csv|
              csv << [uuid, tx.txid, tx.version, tx.marker, tx.flag, tx.lock_time]
            end
            puts "transaction node csv export end #{Time.current}"
            puts "transaction node relation csv export begin #{Time.current}"
            CSV.open(path(rel_file), "a", force_quotes: true) do |csv|
              csv << [block.block_hash, tx.txid]
            end
            puts "transaction node relation csv export end #{Time.current}"
            tx_in_extracter.data = tx
            tx_in_extracter.tx_uuid = uuid
            tx_in_extracter.export
            tx_out_extracter.data = tx
            tx_out_extracter.tx_uuid = uuid
            tx_out_extracter.export
          end
        end
      end

    end
  end
end