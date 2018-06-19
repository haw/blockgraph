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
        BlockGraph::Model::TxOut.import_node(0)
        expect(BlockGraph::Model::TxOut.count).to eq 211
        expect(BlockGraph::Model::TxOut.first.transaction).to eq nil
        expect(BlockGraph::Model::TxOut.all.spent_input).to eq nil
      end
    end

    context 'import node with relation' do
      it 'should be imported tx nodes and relations by csv' do
        BlockGraph::Model::Transaction.import_node(0)
        BlockGraph::Model::TxOut.import_node(0)
        BlockGraph::Model::TxIn.import_node(0)
        BlockGraph::Model::Transaction.import_rel(0)
        BlockGraph::Model::TxOut.import_rel(0)
        BlockGraph::Model::AssetId.import_rel(0)
        BlockGraph::Model::TxIn.import_rel(0)
        expect(BlockGraph::Model::TxOut.count).to eq 211
        expect(BlockGraph::Model::TxOut.first.transaction).to_not eq nil
        expect(BlockGraph::Model::TxOut.all.spent_input).to_not eq nil
      end
    end
  end
end
