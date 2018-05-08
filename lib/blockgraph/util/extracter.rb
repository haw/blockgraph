module BlockGraph
  module Util
    class Extracter

      attr_accessor :block
      attr_accessor :tx
      attr_accessor :tx_in
      attr_accessor :tx_out

      def initialize
        @block = BlockFileManager.new(header: true)
        @tx = TxFileManager.new(header: true)
        @tx_in = TxInFileManager.new(header: true)
        @tx_out = TxOutFileManager.new(header: true)
      end

      def export(blocks)
        initialize if file_closed?
        start_time = Time.current
        puts "export begin #{start_time}"
        blocks.each do |block|
          uuid = SecureRandom.uuid
          @block.node_file << [uuid, block.block_hash, block.header.version, block.header.merkle_root, block.header.time, block.header.bits, block.header.nonce,
                                   block.size, block.height, block.tx_count, block.input_count, block.output_count, block.file_num]
          @block.rel_file << [block.block_hash, block.header.prev_hash]
          @block.flush

          block.transactions.each do |tx|
            tx_uuid = SecureRandom.uuid
            @tx.node_file << [tx_uuid, tx.txid, tx.version, tx.marker, tx.flag, tx.lock_time]
            @tx.rel_file << [tx.txid, block.block_hash]
            @tx.flush

            tx.inputs.each do |tx_in|
              in_uuid = SecureRandom.uuid
              @tx_in.node_file << [in_uuid, tx_in.script_sig, tx_in.script_witness, tx_in.sequence, tx_in.coinbase? ? "" : tx_in.out_point.index, tx_in.coinbase? ? "" : tx_in.out_point.hash]
              @tx_in.rel_file << [in_uuid, tx_uuid]
              @tx_in.flush
            end

            tx.outputs.each_with_index do |tx_out, n|
              out_uuid = SecureRandom.uuid
              if tx_out.script_pubkey.present? && tx_out.script_pubkey.to_hex.size > 2097152
                @tx_out.large_node_file << [out_uuid, tx_out.value, n, tx_out.script_pubkey.to_hex]
              else
                @tx_out.node_file << [out_uuid, tx_out.value, n, tx_out.script_pubkey.present? ? tx_out.script_pubkey.to_hex : '']
              end
              @tx_out.rel_file << [out_uuid, tx_uuid]
              @tx_out.flush
            end
          end
        end
        puts "export end (took times #{(Time.current - start_time)} sec)"
        close_files
      end

      def close_files
        block.close
        tx.close
        tx_in.close
        tx_out.close
      end

      def file_closed?
        block.closed? || tx.closed? || tx_in.closed? || tx_out.closed?
      end

    end
  end
end