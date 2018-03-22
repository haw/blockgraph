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
end
