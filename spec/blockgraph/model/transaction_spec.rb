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
    it do
      BlockGraph::Model::BlockHeader.import("block_headers")
      BlockGraph::Model::Transaction.import("transactions")
      expect(BlockGraph::Model::Transaction.exists?).to be_truthy
    end
  end
end
