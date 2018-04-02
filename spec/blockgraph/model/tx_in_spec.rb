require 'spec_helper'

RSpec.describe BlockGraph::Model::TxIn do
  describe 'create txin node' do
    context 'coinbase' do
      subject {
        tx_in = Bitcoin::TxIn.parse_from_payload("\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\xFF\xFF\x04\x01f\x01\x01\xFF\xFF\xFF\xFF")
        BlockGraph::Model::TxIn.create_from_tx(tx_in)
      }

      it 'should create txin node' do
        allow(BlockGraph::Model::TxOut).to receive(:find_by_outpoint).and_raise('coinbase has not outpoint')
        expect(subject.sequence).to eq 4294967295
        expect(subject.txid).to eq nil
        expect(subject.vout).to eq nil
        expect(subject.script_sig).to eq '01660101'
      end
    end

    context 'not coinbase' do
      before do
        tx = Bitcoin::Tx.parse_from_payload('0200000001e673e0fc9a6bdab56d69e9d27d036568c3c4a06938344b8b36db2cb2c2978ebc0000000049483045022100cb522c8273540b79cc202923c2a8b42f12cbf6b62f15f75328d76ec066a7638d022014b42441a25a66f4f2c3b1d4c4dfc07d7818b8a4f0e678a66d19117a5ee84ef801feffffff0200e1f505000000001976a9145090de42e66e3457adde6a9efa45279ca9a4123088ac00021024010000001976a914c7789562a4c1201e851370f5027b5261d27568f288ac65000000'.htb)
        BlockGraph::Model::Transaction.create_from_tx(tx)
      end
      subject {
        tx_in = Bitcoin::TxIn.parse_from_payload("\x13\x8A\xA9\xD8U\x9D\x92\xC7\x04\xA5\xA7\xF5\xECkZ\xDA\xE1\x88\x9B\xBF\x80\x12\xF5R\xCC\b\xCD1Nm)\xA7\x00\x00\x00\x00kH0E\x02!\x00\xDE\xE9o\n\xF4\xBA\x19\"\xC2f\xB7\x84\xAD\xAAB\xB0\xCD\x13\x16R\xED\xD5\xE4\x11>\xD5i\x84\xE2Q\x11\x87\x02 \x10\x17\xD9-\x1CT_\xF9ss\xD3*#\x8BX\a\xBEvbg\xC0{\x9Bnb\x93>q\xB0\x9F\xCEd\x01!\x031\xA5J\xD6@\x84\xA4\x9E\x15\xE1\xA9\xBC\x99\x1C/K\xDADQE=\xAC\x9D\xBF?A\xF62\x1C>\x8C\x18\xFE\xFF\xFF\xFF")
        BlockGraph::Model::TxIn.create_from_tx(tx_in)
      }

      it 'should create txin node' do
        expect(subject.sequence).to eq 4294967294
        expect(subject.txid).to eq 'a7296d4e31cd08cc52f51280bf9b88e1da5a6becf5a7a504c7929d55d8a98a13'
        expect(subject.vout).to eq 0
        expect(subject.script_sig).to eq '483045022100dee96f0af4ba1922c266b784adaa42b0cd131652edd5e4113ed56984e251118702201017d92d1c545ff97373d32a238b5807be766267c07b9b6e62933e71b09fce6401210331a54ad64084a49e15e1a9bc991c2f4bda4451453dac9dbf3f41f6321c3e8c18'
        expect(subject.out_point.n).to eq 0
        expect(subject.out_point.value).to eq BigDecimal("1.00000000") * BigDecimal(100000000)
      end
    end
  end

  describe 'create txin nodes' do
    before do
      tx = Bitcoin::Tx.parse_from_payload('0200000001e673e0fc9a6bdab56d69e9d27d036568c3c4a06938344b8b36db2cb2c2978ebc0000000049483045022100cb522c8273540b79cc202923c2a8b42f12cbf6b62f15f75328d76ec066a7638d022014b42441a25a66f4f2c3b1d4c4dfc07d7818b8a4f0e678a66d19117a5ee84ef801feffffff0200e1f505000000001976a9145090de42e66e3457adde6a9efa45279ca9a4123088ac00021024010000001976a914c7789562a4c1201e851370f5027b5261d27568f288ac65000000'.htb)
      BlockGraph::Model::Transaction.create_from_tx(tx)
    end

    subject {
      tx_ins = []
      tx_ins << Bitcoin::TxIn.parse_from_payload("\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\xFF\xFF\x04\x01f\x01\x01\xFF\xFF\xFF\xFF")
      tx_ins << Bitcoin::TxIn.parse_from_payload("\x13\x8A\xA9\xD8U\x9D\x92\xC7\x04\xA5\xA7\xF5\xECkZ\xDA\xE1\x88\x9B\xBF\x80\x12\xF5R\xCC\b\xCD1Nm)\xA7\x00\x00\x00\x00kH0E\x02!\x00\xDE\xE9o\n\xF4\xBA\x19\"\xC2f\xB7\x84\xAD\xAAB\xB0\xCD\x13\x16R\xED\xD5\xE4\x11>\xD5i\x84\xE2Q\x11\x87\x02 \x10\x17\xD9-\x1CT_\xF9ss\xD3*#\x8BX\a\xBEvbg\xC0{\x9Bnb\x93>q\xB0\x9F\xCEd\x01!\x031\xA5J\xD6@\x84\xA4\x9E\x15\xE1\xA9\xBC\x99\x1C/K\xDADQE=\xAC\x9D\xBF?A\xF62\x1C>\x8C\x18\xFE\xFF\xFF\xFF")
      BlockGraph::Model::TxIn.builds(tx_ins)
    }

    it 'should create txin nodes' do
      allow(BlockGraph::Model::TxOut).to receive(:find_by_outpoint).and_raise('coinbase has not outpoint')
      expect(subject[0].sequence).to eq 4294967295
      expect(subject[0].txid).to eq nil
      expect(subject[0].vout).to eq nil
      expect(subject[0].script_sig).to eq '01660101'

      expect(subject[1].sequence).to eq 4294967294
      expect(subject[1].txid).to eq 'a7296d4e31cd08cc52f51280bf9b88e1da5a6becf5a7a504c7929d55d8a98a13'
      expect(subject[1].vout).to eq 0
      expect(subject[1].script_sig).to eq '483045022100dee96f0af4ba1922c266b784adaa42b0cd131652edd5e4113ed56984e251118702201017d92d1c545ff97373d32a238b5807be766267c07b9b6e62933e71b09fce6401210331a54ad64084a49e15e1a9bc991c2f4bda4451453dac9dbf3f41f6321c3e8c18'
    end
  end
end
