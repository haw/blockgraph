module BlockGraph
  module Parser
    class BlockInfo

      attr_accessor :file_num # Which # file this block is stored in (blk?????.dat)

      attr_accessor :block_hash
      attr_accessor :header
      attr_accessor :height # height of the entry in the chain. The genesis block has height 0
      attr_accessor :size
      attr_accessor :tx_count # Number of transactions in this block.
      attr_accessor :input_count
      attr_accessor :output_count

      # @param [Bitcoin::BlockHeader] header the block
      # @param [Integer] file_num Which  file this block is stored in (blk?????.dat)
      # @param [Integer] file_pos Byte offset within blk?????.dat where this block's data is stored
      def initialize(header, size, tx_count, tx_in, tx_out, file_num)
        @block_hash = header.hash
        @header = header
        @size = size
        @tx_count = tx_count
        @input_count = tx_in
        @output_count = tx_out
        @file_num = file_num
      end

      # parse raw block data.
      def self.parse_from_raw_data(buf, size, file_num)
        header = Bitcoin::BlockHeader.parse_from_payload(buf.read(80))
        tx_in = tx_out = 0
        tx_count = Bitcoin.unpack_var_int_from_io(buf)
        tx_count.times do
          in_count, out_count = parse_tx_header(buf)
          tx_in += in_count
          tx_out += out_count
        end
        tx_in -= 1 # remove coinbase
        self.new(header, size, tx_count, tx_in, tx_out, file_num)
      end

      # parse BlockInfo data from io.
      def self.parse_from_io(io)
        io.read(32) # hash
        header = Bitcoin::BlockHeader.parse_from_payload(io.read(80))
        height = Bitcoin.unpack_var_int_from_io(io)
        size = Bitcoin.unpack_var_int_from_io(io)
        tx_count = Bitcoin.unpack_var_int_from_io(io)
        input_count = Bitcoin.unpack_var_int_from_io(io)
        output_count = Bitcoin.unpack_var_int_from_io(io)
        file_num = Bitcoin.unpack_var_int_from_io(io)
        b = self.new(header, size, tx_count, input_count, output_count, file_num)
        b.height = height
        b
      end

      def to_payload
        block_hash.htb << header.to_payload << Bitcoin.pack_var_int(height) << Bitcoin.pack_var_int(size) <<
            Bitcoin.pack_var_int(tx_count) << Bitcoin.pack_var_int(input_count) <<
            Bitcoin.pack_var_int(output_count) << Bitcoin.pack_var_int(file_num)
      end

      private

      def self.parse_tx_header(buf)
        buf.read(4) # version

        in_count = Bitcoin.unpack_var_int_from_io(buf)
        witness = false
        if in_count.zero?
          flag = buf.read(1).unpack('c').first
          if flag.zero?
            buf.pos -= 1
          else
            in_count = Bitcoin.unpack_var_int_from_io(buf)
            witness = true
          end
        end

        buf.read(36)
        in_count.times do |i|
          sig_length = Bitcoin.unpack_var_int_from_io(buf)
          if (i + 1) < in_count
            buf.read(sig_length + 4 + 36)
          else
            buf.read(sig_length + 4)
          end
        end

        out_count = Bitcoin.unpack_var_int_from_io(buf)
        buf.read(8)
        out_count.times do |i|
          script_size = Bitcoin.unpack_var_int_from_io(buf)
          if (i + 1) < out_count
            buf.read(script_size + 8)
          else
            buf.read(script_size)
          end
        end

        if witness
          in_count.times do
            witness_count = Bitcoin.unpack_var_int_from_io(buf)
            witness_count.times do
              buf.read(Bitcoin.unpack_var_int_from_io(buf))
            end
          end
        end

        buf.read(4) # lock_time

        [in_count, out_count]
      end

    end
  end
end
