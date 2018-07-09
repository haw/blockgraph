module BlockGraph
  module OpenAssets
    module Util

      autoload :Extractor, 'blockgraph/open_assets/util/extractor'

      # version byte for Open Assets Address
      OA_VERSION_BYTE = 23
      OA_VERSION_BYTE_TESTNET = 115

      class << self
        @@cache = BlockGraph::OpenAssets::Cache::ColoredOutput.new

        # @param[String] txid The transaction id is used by finding from DB.
        # @param[Integer] n The index is specify index of transaction output.
        # @return[Array[BlockGraph::OpenAssets::Model::ColoredOutput]] Return the color output translated uncolored output.
        def get_colored_output(txid, n)
          colored = @@cache.get_output(txid, n)
          return colored unless colored.blank?
          tx = BlockGraph::Model::Transaction.find_by(txid: txid)
          return unless tx
          colored = get_colored_outputs(to_bitcoin_tx(to_payload(tx)))
          colored[n]
        end

        # @param[Bitcoin::Tx] tx The transaction translate BlockGraph::OpenAssets::Model::ColoredOutput.
        # @return[Array[BlockGraph::OpenAssets::Model::ColoredOutput]] Return array of the color outputs.
        def get_colored_outputs(tx)
          unless tx.coinbase_tx?
            tx.outputs.each_with_index do |out, i|
              marker_output_payload = out.script_pubkey.op_return_data
              unless marker_output_payload.nil?
                marker_output = ::OpenAssets::Payload.parse_from_payload(marker_output_payload)
                prev_outs = tx.inputs.map{|input| get_colored_output(input.out_point.txid, input.out_point.index)}
                outputs = compute_asset_ids(prev_outs, i, tx, marker_output.quantities)
                unless outputs.nil?
                  @@cache.put(tx.txid, outputs)
                  return outputs
                end
              end
            end
          end
          tx.outputs.map{|out| BlockGraph::OpenAssets::Model::ColoredOutput.new(out.value, out.script_pubkey, nil, 0, BlockGraph::Constants::OutputType::UNCOLORED)}
        end

        # @param[Array[Bitcoin::TxOut]] prev_outs The array of uncolored outputs.
        # @param[Integer] marker_output_index The integer index of marker output in transaction outputs.
        # @param[Bitcoin:Tx] tx The transaction is a starting point for determining the asset id.
        # @param[Array[Integer]] asset_quantities The quantity is number of asset assign.
        # @return[Array[BlockGraph::OpenAssets::Model::ColoredOutput]] Return array of the color outputs.
        def compute_asset_ids(prev_outs, marker_output_index, tx, asset_quantities)
          outputs = tx.outputs
          return nil if asset_quantities.length > outputs.length - 1 || prev_outs.length == 0 || prev_outs[0].nil?
          result = []

          marker_output = outputs[marker_output_index]

          # Add the issuance outputs
          issuance_asset_id = script_to_asset_id(prev_outs[0].script.to_hex)

          for i in (0..marker_output_index-1)
            value = outputs[i].value
            script = outputs[i].script_pubkey
            if i < asset_quantities.length && asset_quantities[i] > 0
              output = BlockGraph::OpenAssets::Model::ColoredOutput.new(value, script, issuance_asset_id, asset_quantities[i], BlockGraph::Constants::OutputType::ISSUANCE)
            else
              output = BlockGraph::OpenAssets::Model::ColoredOutput.new(value, script, nil, 0, BlockGraph::Constants::OutputType::UNCOLORED)
            end
            result << output
          end

          # Add the marker output
          result << BlockGraph::OpenAssets::Model::ColoredOutput.new(marker_output.value, marker_output.script_pubkey, nil, 0, BlockGraph::Constants::OutputType::MARKER_OUTPUT)

          # remove invalid marker
          remove_outputs = []
          for i in (marker_output_index + 1)..(outputs.length-1)
            marker_output_payload = outputs[i].script_pubkey.op_return_data
            unless marker_output_payload.nil?
              remove_outputs << outputs[i]
              result << BlockGraph::OpenAssets::Model::ColoredOutput.new(
                  outputs[i].value, outputs[i].script_pubkey, nil, 0, BlockGraph::Constants::OutputType::MARKER_OUTPUT)
              next
            end
          end
          remove_outputs.each{|o|outputs.delete(o)}

          # Add the transfer outputs
          input_enum = prev_outs.each
          input_units_left = 0
          index = 0
          for i in (marker_output_index + 1)..(outputs.length-1)
            output_asset_quantity = (i <= asset_quantities.length) ? asset_quantities[i-1] : 0
            output_units_left = output_asset_quantity
            asset_id,metadata = nil
            while output_units_left > 0
              index += 1
              if input_units_left == 0
                begin
                  current_input = input_enum.next
                  input_units_left = current_input.asset_quantity
                rescue StopIteration => e
                  return nil
                end
              end
              unless current_input.asset_id.nil?
                progress = [input_units_left, output_units_left].min
                output_units_left -= progress
                input_units_left -= progress
                if asset_id.nil?
                  # This is the first input to map to this output
                  asset_id = current_input.asset_id
                  metadata = current_input.metadata
                elsif asset_id != current_input.asset_id
                  return nil
                end
              end
            end

            if output_asset_quantity == 0
              result << BlockGraph::OpenAssets::Model::ColoredOutput.new(outputs[i].value, outputs[i].script_pubkey,
                                                                         asset_id, output_asset_quantity, BlockGraph::Constants::OutputType::UNCOLORED, metadata)
            else
              result << BlockGraph::OpenAssets::Model::ColoredOutput.new(outputs[i].value, outputs[i].script_pubkey,
                                                                         asset_id, output_asset_quantity, BlockGraph::Constants::OutputType::TRANSFER, metadata)
            end
          end
          result
        end

        def to_colored_outputs(tx)
          unless tx.coinbase_tx?
            i = tx.outputs.index{|out| !out.script_pubkey.op_return_data.nil?}
            colored = []
            marker_output = ::OpenAssets::Payload.parse_from_payload(tx.outputs[i].script_pubkey.op_return_data) if i
            unless marker_output.nil?
              (0...i).each {|j|
                if j < marker_output.quantities.length && marker_output.quantities[j] > 0
                  colored << BlockGraph::OpenAssets::Model::ColoredOutput.new(tx.outputs[j].value, tx.outputs[j].script_pubkey, nil, marker_output.quantities[j], BlockGraph::Constants::OutputType::ISSUANCE)
                else
                  colored << BlockGraph::OpenAssets::Model::ColoredOutput.new(tx.outputs[j].value, tx.outputs[j].script_pubkey, nil, 0, BlockGraph::Constants::OutputType::UNCOLORED)
                end
              }
              colored << BlockGraph::OpenAssets::Model::ColoredOutput.new(tx.outputs[i].value, tx.outputs[i].script_pubkey, nil, 0, BlockGraph::Constants::OutputType::MARKER_OUTPUT)
              ((i + 1)...tx.outputs.size).each {|j|
                asset_quantity = (j <= marker_output.quantities.length ? marker_output.quantities[j-1] : 0)
                if asset_quantity > 0
                  colored << BlockGraph::OpenAssets::Model::ColoredOutput.new(tx.outputs[j].value, tx.outputs[j].script_pubkey, nil, asset_quantity, BlockGraph::Constants::OutputType::TRANSFER)
                else
                  colored << BlockGraph::OpenAssets::Model::ColoredOutput.new(tx.outputs[j].value, tx.outputs[j].script_pubkey, nil, asset_quantity, BlockGraph::Constants::OutputType::UNCOLORED)
                end
              }
              return colored
            end
          end
          tx.outputs.map{|out| BlockGraph::OpenAssets::Model::ColoredOutput.new(out.value, out.script_pubkey, nil, 0, BlockGraph::Constants::OutputType::UNCOLORED)}
        end

        def cache
          @@cache
        end

        # parse issuance p2sh which contains asset definition pointer
        def parse_issuance_p2sh_pointer(script_sig)
          script = Bitcoin::Script.parse_from_payload(script_sig).chunks.last.pushed_data
          redeem_script = Bitcoin::Script.parse_from_payload(script)
          return nil unless redeem_script.chunks[1].bth.to_i(16) == Bitcoin::Script::OP_DROP
          asset_def = to_bytes(redeem_script.chunks[0].to_s.bth)[0..-1].map{|x|x.to_i(16).chr}.join.pushed_data
          asset_def && asset_def.start_with?('u=') ? asset_def : nil
        end

        def script_to_asset_id(script)
          hash_to_asset_id(Bitcoin::hash160(script))
        end

        def hash_to_asset_id(hash)
          Bitcoin::encode_base58_address(hash, oa_version_byte.to_s(16))
        end

        private
        def oa_version_byte
          Bitcoin.chain_params == :mainnet ? OA_VERSION_BYTE : OA_VERSION_BYTE_TESTNET
        end

        def find_tx(txid)
          BlockGraph::Model::Transaction.find_by(txid: txid)
        end

        def to_payload(tx)
          tx.nil? ? '' : tx.to_payload
        end

        def to_bitcoin_tx(payload)
          Bitcoin::Tx.parse_from_payload(payload)
        end

        def to_bytes(string)
          string.each_char.each_slice(2).map{|v|v.join}
        end
      end

    end
  end
end
