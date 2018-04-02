require 'spec_helper'

RSpec.describe BlockGraph::Model::TxOut do
  describe 'create txout node' do
    subject {
      outputs = []; tx_outs = []
      outputs << Bitcoin::TxOut.parse_from_payload("\x80\xF0\xFA\x02\x00\x00\x00\x00\x19v\xA9\x14\x84\x8E:\x1E\xAB4\xE3\xD8\x11\xE7j\xB7\x82\x06y\xF3\xDB\xFE\xB2N\x88\xAC")
      outputs << Bitcoin::TxOut.parse_from_payload("\xD8\xDE\xFA\x02\x00\x00\x00\x00\x19v\xA9\x14cu\xCF\xA36TH\xA4\xC8E\x8D\xB9\x1A\xC3B\x95u\xB2\xE6\x1F\x88\xAC")
      outputs.each_with_index do |tx_out, i|
        tx_outs << BlockGraph::Model::TxOut.create_from_tx(tx_out, i)
      end
      tx_outs
    }

    it 'should create txout node' do
      out0, out1 = subject
      expect(out0.value).to eq BigDecimal("0.50000000") * BigDecimal(100000000)
      expect(out0.n).to eq 0
      expect(out0.script_pubkey).to eq '76a914848e3a1eab34e3d811e76ab7820679f3dbfeb24e88ac'
      expect(out1.value).to eq BigDecimal("0.49995480") * BigDecimal(100000000)
      expect(out1.n).to eq 1
      expect(out1.script_pubkey).to eq '76a9146375cfa3365448a4c8458db91ac3429575b2e61f88ac'
    end
  end

  describe 'create txout nodes' do
    subject {
      outputs = []
      outputs << Bitcoin::TxOut.parse_from_payload("\x80\xF0\xFA\x02\x00\x00\x00\x00\x19v\xA9\x14\x84\x8E:\x1E\xAB4\xE3\xD8\x11\xE7j\xB7\x82\x06y\xF3\xDB\xFE\xB2N\x88\xAC")
      outputs << Bitcoin::TxOut.parse_from_payload("\xD8\xDE\xFA\x02\x00\x00\x00\x00\x19v\xA9\x14cu\xCF\xA36TH\xA4\xC8E\x8D\xB9\x1A\xC3B\x95u\xB2\xE6\x1F\x88\xAC")
      BlockGraph::Model::TxOut.builds(outputs)
    }

    it 'should create txout nodes' do
      out0, out1 = subject
      expect(out0.value).to eq BigDecimal("0.50000000") * BigDecimal(100000000)
      expect(out0.n).to eq 0
      expect(out0.script_pubkey).to eq '76a914848e3a1eab34e3d811e76ab7820679f3dbfeb24e88ac'
      expect(out1.value).to eq BigDecimal("0.49995480") * BigDecimal(100000000)
      expect(out1.n).to eq 1
      expect(out1.script_pubkey).to eq '76a9146375cfa3365448a4c8458db91ac3429575b2e61f88ac'
    end
  end
end
