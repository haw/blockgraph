module BlockGraph
  module Parser
    class Configuration

      attr_reader :out_dir, :coin_dir

      def initialize(out_dir, coin_dir)
        @out_dir = out_dir
        @coin_dir = coin_dir
        init_dir
        load_coin_network
      end

      def parser_dir
        "#{out_dir}/parser"
      end

      def utxo_cache_file
        "#{parser_dir}/utxoCache.dat"
      end

      def utxo_address_state_path
        "#{parser_dir}/utxoAddressState"
      end

      def utxo_script_state_path
        "#{parser_dir}/utxoScriptState"
      end

      def address_path
        "#{parser_dir}/address"
      end

      def block_list_path
        "#{parser_dir}/blockList.dat"
      end

      def tx_updates_file_path
        "#{parser_dir}/txUpdates"
      end

      def path_for_block_file(file_num)
        "#{coin_dir}/blocks/blk#{file_num.to_s.rjust(5, '0')}.dat"
      end

      private

      # change coin network from coin dirname.
      def load_coin_network
        if coin_dir.include?('testnet')
          Bitcoin.chain_params = :testnet
        elsif coin_dir.include?('regtest')
          Bitcoin.chain_params = :regtest
        else
          Bitcoin.chain_params = :mainnet
        end
      end

      def init_dir
        FileUtils.mkdir_p([parser_dir])
      end
    end
  end
end
