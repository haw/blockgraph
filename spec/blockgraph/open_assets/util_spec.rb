require 'spec_helper'

RSpec.describe BlockGraph::OpenAssets::Util do
  describe 'get_colored_outputs' do

    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }
    let(:prev_tx){ Bitcoin::Tx.parse_from_payload("0200000001681c7decdae8ed79d74a8dc687c597c01c11f61dc3e2bbd76fa97f7f5670a979000000006b4830450221008b0f3c2fd4b34d166fd7856b018464ae79d53d737e302a3bf3552c49170d2f76022002fb451cab4aae5af821e1788289ab6a7550361b95371c9582f05a4b042bebd00121033610b0c607af43d423a535edddd549860c84341a65050f624c3da829988199d4feffffff0240420f00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac499b6105000000001976a9142ff7ef995ba254c0c65b6bfdcf6198f590f4ef5b88ac7c2b1400".htb) }
    let(:next_tx){ Bitcoin::Tx.parse_from_payload("010000000151e2ff157e3330abc4684e1a4d26967504c0b9a31ea5fa47f6353451fba948ac030000006a47304402203778ac9e16a9213aafff31b0a35d6584ce3f74ef47f70d44d937ca6be929b6f70220404a4e6ec25fcbeecbaf6eabb12519e63e69f78f935228ba63659e30a41d7e1e0121029eca9e6696d46fca9aaabdd66934a6ed6f34b7cb7b15a4d600154a7584f7a93cffffffff020000000000000000096a074f41010001010058020000000000001976a914b9dd2eaea0ba7baea5d9af959f8dffb620f6a97288ac00000000".htb)}

    context 'depth 1' do
      before do
        mock_prev_tx = double('Util find by prev tx', txid: prev_tx.txid)
        allow(BlockGraph::Model::Transaction).to receive(:find_by).and_return(mock_prev_tx)
        allow(mock_prev_tx).to receive(:to_payload).and_return(prev_tx.to_payload)
        @ret = BlockGraph::OpenAssets::Util.get_colored_outputs(tx)
      end

      it 'should return color outputs' do
        expect(@ret[0].value_to_btc.to_f).to eq 0.009182
        expect(@ret[1].value_to_btc.to_f).to eq 0.000206
        expect(@ret[2].value_to_btc.to_f).to eq 0.000206
        expect(@ret[3].value_to_btc.to_f).to eq 0.000206
        expect(@ret[4].value_to_btc.to_f).to eq 0
      end

      it 'should be set asset id' do
        expect(@ret[0].asset_id).to eq nil # This output asset quantity is 0
        expect(@ret[1].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
        expect(@ret[2].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
        expect(@ret[3].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
        expect(@ret[4].asset_id).to eq nil # Marker output
      end
    end


    context 'depth 2' do
      before do
        mock_tx = double('Util find by tx', txid: tx.txid)
        mock_prev_tx = double('Util find by prev tx', txid: prev_tx.txid)
        allow(BlockGraph::Model::Transaction).to receive(:find_by).and_return(mock_tx, mock_prev_tx)
        allow(mock_tx).to receive(:to_payload).and_return(tx.to_payload)
        allow(mock_prev_tx).to receive(:to_payload).and_return(prev_tx.to_payload)
        @ret = BlockGraph::OpenAssets::Util.get_colored_outputs(next_tx)
      end

      it 'should be set asset id' do
        expect(@ret[0].asset_id).to eq nil # Marker output
        expect(@ret[1].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
      end

    end
  end

  describe 'parse_issueance_p2sh_pointer' do
    let(:valid_script){ '47304402202254f7da7c3fe2bf2a4dd2c3e255aa3ad61415550f648b564aea335f8fcd3d92022062eab5c01a5e33eb726f976ebd3b35d3991f8a45da56d64e1cd3fd5178f8c9a6012102effb2edfcf826d43027feae226143bdac058ad2e87b7cec26f97af2d357ddefa3217753d68747470733a2f2f676f6f2e676c2f626d564575777576a9148911455a265235b2d356a1324af000d4dae0326288ac'.htb }
    let(:invalid_script){ '47304402203ab5ed931276e28a09cfef2cf824ee8a07659eb22751eee0500df8bb7b57f90f02206a36cbb627035391d762104ede2e613311ea2acbb49554e2f7f5ed49d328558d012102ed63c39d95a9a577403cd8517a0a6a70f5f21444741fd58b928195879ce10fd41b517576a9144dc66e4e0adef395980d547db19918773763f02388ac'.htb }

    context 'valid p2sh pointer' do
      subject {
        BlockGraph::OpenAssets::Util.parse_issuance_p2sh_pointer(valid_script)
      }
      it 'should return pointer' do
        expect(subject).to eq 'u=https://goo.gl/bmVEuw'
      end
    end

    context 'invalid p2sh pointer' do
      subject {
        BlockGraph::OpenAssets::Util.parse_issuance_p2sh_pointer(invalid_script)
      }
      it 'should return nil' do
        expect(subject).to be nil
      end
    end
  end

  describe 'get_colored_outputs' do
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }
    let(:prev_tx){ Bitcoin::Tx.parse_from_payload("0200000001681c7decdae8ed79d74a8dc687c597c01c11f61dc3e2bbd76fa97f7f5670a979000000006b4830450221008b0f3c2fd4b34d166fd7856b018464ae79d53d737e302a3bf3552c49170d2f76022002fb451cab4aae5af821e1788289ab6a7550361b95371c9582f05a4b042bebd00121033610b0c607af43d423a535edddd549860c84341a65050f624c3da829988199d4feffffff0240420f00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac499b6105000000001976a9142ff7ef995ba254c0c65b6bfdcf6198f590f4ef5b88ac7c2b1400".htb) }
    let(:next_tx){ Bitcoin::Tx.parse_from_payload("010000000151e2ff157e3330abc4684e1a4d26967504c0b9a31ea5fa47f6353451fba948ac030000006a47304402203778ac9e16a9213aafff31b0a35d6584ce3f74ef47f70d44d937ca6be929b6f70220404a4e6ec25fcbeecbaf6eabb12519e63e69f78f935228ba63659e30a41d7e1e0121029eca9e6696d46fca9aaabdd66934a6ed6f34b7cb7b15a4d600154a7584f7a93cffffffff020000000000000000096a074f41010001010058020000000000001976a914b9dd2eaea0ba7baea5d9af959f8dffb620f6a97288ac00000000".htb)}

    context 'do not created nodes' do
      it 'should return colored output without asset id' do
        outputs = BlockGraph::OpenAssets::Util.get_colored_outputs(next_tx)
        expect(outputs.all?{|out| out.asset_id.nil?}).to be_truthy
      end
    end

    context 'created nodes' do
      before do
        [prev_tx, tx, next_tx].each do |tx|
          BlockGraph::Model::Transaction.create_from_tx(tx, 0)
        end
        BlockGraph::Model::Transaction.all.each do |tx|
          tx_outs = tx.outputs.order(n: :asc)
          outputs = BlockGraph::OpenAssets::Util.to_colored_outputs(Bitcoin::Tx.parse_from_payload(tx.to_payload))
          outputs.each_with_index do |tx_out, n|
            tx_outs[n].asset_quantity = tx_out.asset_quantity
            tx_outs[n].oa_output_type = tx_out.oa_output_type
            tx_outs[n].save!
          end
        end
      end

      it 'should return colored output with asset id' do
        outputs = BlockGraph::OpenAssets::Util.get_colored_outputs(next_tx)
        expect(outputs[0].asset_id).to eq nil # marker output
        expect(outputs[0].oa_output_type).to eq BlockGraph::Constants::OutputType::MARKER_OUTPUT
        (1...outputs.size).each do |i|
          expect(outputs[i].asset_id).to eq "oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci"
          expect(outputs[i].oa_output_type).to eq BlockGraph::Constants::OutputType::TRANSFER
        end
      end

      it 'should cache properties' do
        BlockGraph::OpenAssets::Util.get_colored_outputs(next_tx)
        next_tx.inputs.each do |input|
          expect(BlockGraph::OpenAssets::Util.cache.get_output(input.out_point.txid, input.out_point.index)).to_not be_blank
        end
      end

    end

  end

  describe 'compute_asset_ids' do
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }

    it 'should return colored outputs include asset id' do
      prev_outs = BlockGraph::OpenAssets::Util.to_colored_outputs(tx)
      i = tx.outputs.index{|out| !out.script_pubkey.op_return_data.nil?}
      marker_output = OpenAssets::Payload.parse_from_payload(prev_outs[i].script.op_return_data)
      outputs = BlockGraph::OpenAssets::Util.compute_asset_ids(prev_outs, i, tx, marker_output.quantities)

      expect(outputs[0].asset_id).to eq nil # This output asset quantity is 0
      expect(outputs[1].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
      expect(outputs[2].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
      expect(outputs[3].asset_id).to eq 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci'
      expect(outputs[4].asset_id).to eq nil # Marker output
    end

  end
end
