module BlockGraph
  module Util
    class Extractor

      attr_accessor :block
      attr_accessor :tx
      attr_accessor :tx_in
      attr_accessor :tx_out

      def initialize
        @block = BlockFileManager.new
        @tx = TxFileManager.new
        @tx_in = TxInFileManager.new
        @tx_out = TxOutFileManager.new
        @block_node = []
        @block_rel = []
        @tx_node = []
        @tx_rel = []
        @in_node = []
        @in_rel = []
        @out_node = []
        @out_large_node = []
        @out_rel = []
      end

      def export(blocks)
        start_time = Time.current
        puts "export begin #{start_time}"
        parallel_format_data(blocks)
        parallel_export
        puts "export end #{Time.current} (took times #{(Time.current - start_time)} sec)"
      end

      def parallel_export
        Parallel.map(
            [[@block, @block_node, @block_rel], [@tx, @tx_node, @tx_rel], [@tx_in, @in_node, @in_rel], [@tx_out, [@out_node, @out_large_node], @out_rel]],
            in_thread: 4
        ) do |file, nodes, rels|
          file.export(nodes, rels)
        end
      end

      def parallel_format_data(blocks)
        Parallel.map(blocks, in_thread: 4, finish: -> (item, i, result) {
          @block_node << result[0]
          @block_rel << result[1]
          result[2].each{ |node| @tx_node << node }
          result[3].each{ |rel| @tx_rel << rel }
          result[4].each{ |node| @in_node << node }
          result[5].each{ |rel| @in_rel << rel }
          result[6].each{ |node| @out_node << node }
          result[7].each{ |node| @out_large_node << node }
          result[8].each{ |rel| @out_rel << rel }
        }) do |block|
          tx_node = []; tx_rel = []
          in_node = []; in_rel = []
          out_node = []; out_large_node = []; out_rel = []
          uuid = SecureRandom.uuid
          block_node = [uuid, block.block_hash, block.header.version, block.header.merkle_root, block.header.time, block.header.bits, block.header.nonce,
                        block.size, block.height, block.tx_count, block.input_count, block.output_count, block.file_num, block.file_pos]
          block_rel = [block.block_hash, block.header.prev_hash]

          block.transactions.each do |tx|
            tx_uuid = SecureRandom.uuid
            tx_node << [tx_uuid, tx.txid, tx.version, tx.marker, tx.flag, tx.lock_time]
            tx_rel << [tx.txid, block.block_hash]

            tx.inputs.each do |tx_in|
              in_uuid = SecureRandom.uuid
              in_node << [in_uuid, tx_in.coinbase? ? '' : tx_in.script_sig.to_hex, tx_in.script_witness.empty? ? '' : tx_in.script_witness.to_s, tx_in.sequence, tx_in.coinbase? ? '' : tx_in.out_point.index, tx_in.coinbase? ? '' : tx_in.out_point.txid]
              in_rel << [in_uuid, tx_uuid]
            end

            outputs = BlockGraph::OpenAssets::Util.to_color_outputs(Bitcoin::Tx.parse_from_payload(tx.to_payload))
            outputs.each_with_index do |tx_out, n|
              out_uuid = SecureRandom.uuid
              if tx_out.script_pubkey.present? && tx_out.script_pubkey.to_hex.size > 2097152
                out_large_node << [out_uuid, tx_out.value, n, tx_out.script_pubkey.to_hex, tx_out.asset_quantity, tx_out.output_type]
              else
                out_node << [out_uuid, tx_out.value, n, tx_out.script_pubkey.present? ? tx_out.script_pubkey.to_hex : '', tx_out.asset_quantity, tx_out.output_type]
              end
              out_rel << [out_uuid, tx_uuid]
            end
          end
          [block_node, block_rel, tx_node, tx_rel, in_node, in_rel, out_node, out_large_node, out_rel]
        end
      end

      def parallel_format_block(blocks)
        Parallel.map(blocks, in_thread: 4, finish: -> (item, i, result) {
          @block_node << result[0]
        }) do |block|
          ['', block.block_hash, block.header.version, block.header.merkle_root, block.header.time, block.header.bits, block.header.nonce,
           block.size, block.height, block.tx_count, block.input_count, block.output_count, block.file_num, block.file_pos]
        end
      end

      def export_update(blocks)
        CSV.open(File.join(block.dir, "block_height_update.csv"), "w", force_quotes: true) do |csv|
          csv << ["block_hash", "height"]
          blocks.each{ |block| csv << [block.block_hash, block.height]}
        end
      end

    end
  end
end
