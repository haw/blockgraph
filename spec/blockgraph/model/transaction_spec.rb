require 'spec_helper'

RSpec.describe BlockGraph::Model::Transaction do
  describe 'create tx node' do
    subject {
      tx = Bitcoin::Tx.parse_from_payload('0200000001138aa9d8559d92c704a5a7f5ec6b5adae1889bbf8012f552cc08cd314e6d29a7000000006b483045022100dee96f0af4ba1922c266b784adaa42b0cd131652edd5e4113ed56984e251118702201017d92d1c545ff97373d32a238b5807be766267c07b9b6e62933e71b09fce6401210331a54ad64084a49e15e1a9bc991c2f4bda4451453dac9dbf3f41f6321c3e8c18feffffff0280f0fa02000000001976a914848e3a1eab34e3d811e76ab7820679f3dbfeb24e88acd8defa02000000001976a9146375cfa3365448a4c8458db91ac3429575b2e61f88ac65000000'.htb)
      BlockGraph::Model::Transaction.create_from_tx(tx)
    }

    it 'should create tx node' do
      expect(subject.txid).to eq '4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7'
      expect(subject.version).to eq 2
      expect(subject.lock_time).to eq 101
    end
  end

  describe 'create tx nodes' do
    subject {
      txes = []
      txes << Bitcoin::Tx.parse_from_payload('0200000001138aa9d8559d92c704a5a7f5ec6b5adae1889bbf8012f552cc08cd314e6d29a7010000006a473044022059786081761e452d0cd49dadea7d0d8da7c0e7f2c82ada32fb944971aaed12c302202604d16b790601b2e4c36d8553e5d115605274141fec268bb016bee9c2cd9a33012103a4b27008cfc7e974e9f1625b8793fe23d16d170ed8b3e389729892efcc3413aafeffffff02580f1a1e010000001976a91465c00084246b4aa565a60da932a8ba938207158788ac00e1f505000000001976a91439ed8cec4bcfbb102b2e8de660f5630a96ce247588ac65000000'.htb)
      txes << Bitcoin::Tx.parse_from_payload('0200000001138aa9d8559d92c704a5a7f5ec6b5adae1889bbf8012f552cc08cd314e6d29a7000000006b483045022100dee96f0af4ba1922c266b784adaa42b0cd131652edd5e4113ed56984e251118702201017d92d1c545ff97373d32a238b5807be766267c07b9b6e62933e71b09fce6401210331a54ad64084a49e15e1a9bc991c2f4bda4451453dac9dbf3f41f6321c3e8c18feffffff0280f0fa02000000001976a914848e3a1eab34e3d811e76ab7820679f3dbfeb24e88acd8defa02000000001976a9146375cfa3365448a4c8458db91ac3429575b2e61f88ac65000000'.htb)
      BlockGraph::Model::Transaction.builds(txes)
    }

    it 'should create tx nodes' do
      expect(subject.size).to eq 2
      expect(subject[-1].txid).to eq '4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7'
      expect(subject[-1].version).to eq 2
      expect(subject[-1].lock_time).to eq 101
    end
  end

  describe 'import' do
    subject(:blocks) {
      index = BlockGraph::Parser::ChainIndex.new(test_configuration)
      index.update
      index.reorg_blocks
      index.blocks_to_add
    }

    before do
      if Dir.glob(File.join(neo4j_dir, "*")).empty?
        extr = BlockGraph::Util::Extractor.new
        extr.export(blocks)
      end
    end

    context 'import only node' do
      it 'should be imported tx nodes by csv' do
        BlockGraph::Model::Transaction.import_node(0)
        expect(BlockGraph::Model::Transaction.count).to eq 106
        expect(BlockGraph::Model::Transaction.first.block).to eq nil
      end
    end

    context 'import node with relation' do
      it 'should be imported tx nodes and relations by csv' do
        BlockGraph::Model::BlockHeader.import_node(0)
        BlockGraph::Model::Transaction.import_node(0)
        BlockGraph::Model::TxOut.import_node(0)
        BlockGraph::Model::TxIn.import_node(0)
        BlockGraph::Model::Transaction.import_rel(0)
        BlockGraph::Model::TxOut.import_rel(0)
        BlockGraph::Model::TxIn.import_rel(0)
        expect(BlockGraph::Model::Transaction.count).to eq 106
        expect(BlockGraph::Model::Transaction.first.block).to_not eq nil
        expect(BlockGraph::Model::Transaction.first.inputs).to_not be_blank
        expect(BlockGraph::Model::Transaction.first.outputs).to_not be_blank
      end
    end
  end

  describe 'openassets_tx?' do
    let(:openassets_tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }
    let(:prev_tx){ Bitcoin::Tx.parse_from_payload("0200000001681c7decdae8ed79d74a8dc687c597c01c11f61dc3e2bbd76fa97f7f5670a979000000006b4830450221008b0f3c2fd4b34d166fd7856b018464ae79d53d737e302a3bf3552c49170d2f76022002fb451cab4aae5af821e1788289ab6a7550361b95371c9582f05a4b042bebd00121033610b0c607af43d423a535edddd549860c84341a65050f624c3da829988199d4feffffff0240420f00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac499b6105000000001976a9142ff7ef995ba254c0c65b6bfdcf6198f590f4ef5b88ac7c2b1400".htb) }

    before do
      allow(BlockGraph::OpenAssets::Util).to receive(:find_tx).and_return(double('Util find tx', txid: prev_tx.txid))
      allow(BlockGraph::OpenAssets::Util).to receive(:to_payload).and_return(double('Util payload'))
      allow(BlockGraph::OpenAssets::Util).to receive(:to_bitcoin_tx).and_return(prev_tx)
      @openassets_tx = BlockGraph::Model::Transaction.create_from_tx(openassets_tx)
      colored_outputs = BlockGraph::OpenAssets::Util.get_color_outputs_from_tx(openassets_tx)
      @openassets_tx.outputs.each do |out|
        oa_out = colored_outputs.find(nil){|colored| colored.script.to_hex == out.script_pubkey }
        out.apply_oa_attributes(oa_out) if oa_out
      end
    end

    it 'should return true' do
      expect(@openassets_tx.openassets_tx?).to be_truthy
    end
  end
end
