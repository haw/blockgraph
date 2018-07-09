require 'spec_helper'

RSpec.describe BlockGraph::OpenAssets::Util::Extractor do

  describe 'export_asset_ids' do
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }
    let(:prev_tx){ Bitcoin::Tx.parse_from_payload("0200000001681c7decdae8ed79d74a8dc687c597c01c11f61dc3e2bbd76fa97f7f5670a979000000006b4830450221008b0f3c2fd4b34d166fd7856b018464ae79d53d737e302a3bf3552c49170d2f76022002fb451cab4aae5af821e1788289ab6a7550361b95371c9582f05a4b042bebd00121033610b0c607af43d423a535edddd549860c84341a65050f624c3da829988199d4feffffff0240420f00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac499b6105000000001976a9142ff7ef995ba254c0c65b6bfdcf6198f590f4ef5b88ac7c2b1400".htb) }

    before do
      FileUtils.rm_rf(neo4j_dir, :secure => true)
      FileUtils.mkdir(neo4j_dir)

      BlockGraph::Model::Transaction.create_from_tx(tx, 0)
      BlockGraph::Model::Transaction.create_from_tx(prev_tx, 0)

      allow(BlockGraph::OpenAssets::Util).to receive(:find_tx).and_return(double('Util find tx', txid: tx.txid))
      allow(BlockGraph::OpenAssets::Util).to receive(:to_payload).and_return(double('Util payload'))
      allow(BlockGraph::OpenAssets::Util).to receive(:to_bitcoin_tx).and_return(tx, prev_tx)
      @txes = BlockGraph::Model::Transaction.all
    end

    after do
      FileUtils.rm_rf(neo4j_dir, :secure => true)
      FileUtils.mkdir(neo4j_dir)
    end

    context 'to work properly' do
      let(:outputs) {
        outputs = []
        @txes.each do |tx|
          outputs << BlockGraph::OpenAssets::Util.get_colored_outputs(Bitcoin::Tx.parse_from_payload(tx.to_payload))
        end
        outputs.flatten!
      }

      it 'should export csv in $NEO4J_HOME' do
        BlockGraph::OpenAssets::Util::Extractor.export_asset_ids(@txes)
        expect(File.exists?(File.join(neo4j_dir, "open_assets00000.csv"))).to be_truthy
      end

      it 'should be same value in csv' do
        BlockGraph::OpenAssets::Util::Extractor.export_asset_ids(@txes)
        CSV.read(File.join(neo4j_dir, "open_assets00000.csv"), headers: true).each_with_index do |row, i|
          expect(row[1].to_i).to eq outputs[i].asset_quantity
          expect(row[2].to_i).to eq outputs[i].output_type
        end

        CSV.read(File.join(neo4j_dir, "open_assets00000_rel.csv"), headers: true).each_with_index do |row, i|
          expect(row[1]).to eq outputs[i].asset_id.to_s
        end
      end
    end

  end

end
