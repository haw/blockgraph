require 'spec_helper'

RSpec.describe BlockGraph::Model::AssetId do

  describe 'find_or_create' do

    let(:asset_id){ 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci' }

    context 'find' do
      before do
        mock = double('AssetId')
        allow(mock).to receive(:asset_id).and_return(asset_id)
        allow(mock).to receive(:first).and_return(mock)
        allow(BlockGraph::Model::AssetId).to receive(:with_asset_id).and_return(mock)
      end

      it 'should return asset id' do
        expect(BlockGraph::Model::AssetId).to receive(:with_asset_id).with(asset_id)
        expect(BlockGraph::Model::AssetId.find_or_create(asset_id))
      end
    end

    context 'create' do
      it 'should create asset id' do
        expect(BlockGraph::Model::AssetId).to receive(:with_asset_id).with(asset_id).and_call_original
        expect{
          BlockGraph::Model::AssetId.find_or_create(asset_id)
        }.to change{ BlockGraph::Model::AssetId.count }.by(1)
      end
    end
  end

  describe 'issueance_txs' do
    let(:asset_id){ BlockGraph::Model::AssetId.find_or_create('oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci' )}
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }
    let(:prev_tx){ Bitcoin::Tx.parse_from_payload("0200000001681c7decdae8ed79d74a8dc687c597c01c11f61dc3e2bbd76fa97f7f5670a979000000006b4830450221008b0f3c2fd4b34d166fd7856b018464ae79d53d737e302a3bf3552c49170d2f76022002fb451cab4aae5af821e1788289ab6a7550361b95371c9582f05a4b042bebd00121033610b0c607af43d423a535edddd549860c84341a65050f624c3da829988199d4feffffff0240420f00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac499b6105000000001976a9142ff7ef995ba254c0c65b6bfdcf6198f590f4ef5b88ac7c2b1400".htb) }
    let(:next_tx){ Bitcoin::Tx.parse_from_payload("010000000151e2ff157e3330abc4684e1a4d26967504c0b9a31ea5fa47f6353451fba948ac030000006a47304402203778ac9e16a9213aafff31b0a35d6584ce3f74ef47f70d44d937ca6be929b6f70220404a4e6ec25fcbeecbaf6eabb12519e63e69f78f935228ba63659e30a41d7e1e0121029eca9e6696d46fca9aaabdd66934a6ed6f34b7cb7b15a4d600154a7584f7a93cffffffff020000000000000000096a074f41010001010058020000000000001976a914b9dd2eaea0ba7baea5d9af959f8dffb620f6a97288ac00000000".htb)}

    before do
      [prev_tx, tx, next_tx].each do |tx|
        BlockGraph::Model::Transaction.create_from_tx(tx, 0)
      end
      BlockGraph::Model::Transaction.all.each do |tx|
        tx_outs = tx.outputs.order(n: :asc)
        outputs = BlockGraph::OpenAssets::Util.get_colored_outputs(Bitcoin::Tx.parse_from_payload(tx.to_payload))
        outputs.each_with_index do |tx_out, n|
          tx_outs[n].asset_quantity = tx_out.asset_quantity
          tx_outs[n].oa_output_type = tx_out.oa_output_type
          tx_outs[n].asset_id = BlockGraph::Model::AssetId.find_or_create(tx_out.asset_id) if tx_out.asset_id
          tx_outs[n].save!
        end
      end
    end

    it 'should return issueance transactions' do
      txs = asset_id.issuance_txs
      expect(txs.size).to eq 1
      expect(txs[0].txid).to eq tx.txid
    end
  end

end
