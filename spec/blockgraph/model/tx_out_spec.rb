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
      before do
        BlockGraph::Model::TxOut.import_node(0)
      end

      it 'should be imported tx nodes by csv' do
        expect(BlockGraph::Model::TxOut.count).to eq 211
        expect(BlockGraph::Model::TxOut.first.transaction).to eq nil
        expect(BlockGraph::Model::TxOut.all.spent_input).to eq nil
      end

      it 'should set some properties' do
        out = BlockGraph::Model::TxOut.last
        expect(out.value).to_not be_blank
        expect(out.n).to_not be_blank
        expect(out.script_pubkey).to_not be_blank
        expect(out.asset_quantity).to_not be_blank
        expect(out.oa_output_type).to_not be_blank
      end
    end

    context 'import node with relation' do
      it 'should be imported tx nodes and relations by csv' do
        BlockGraph::Model::Transaction.import_node(0)
        BlockGraph::Model::TxOut.import_node(0)
        BlockGraph::Model::TxIn.import_node(0)
        BlockGraph::Model::Transaction.import_rel(0)
        BlockGraph::Model::TxOut.import_rel(0)
        BlockGraph::Model::TxIn.import_rel(0)
        expect(BlockGraph::Model::TxOut.count).to eq 211
        expect(BlockGraph::Model::TxOut.first.transaction).to_not eq nil
        expect(BlockGraph::Model::TxOut.all.spent_input).to_not eq nil
      end
    end
  end

  describe 'output_type' do
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }

    before do
      BlockGraph::Model::Transaction.create_from_tx(tx, 0)
    end

    it 'should get the transaction type' do
      outputs = BlockGraph::Model::Transaction.find_by(txid: tx.txid).outputs
      expect(outputs[0].output_type).to eq 'nonstandard'
      expect(outputs[1].output_type).to eq 'pubkeyhash'
      expect(outputs[2].output_type).to eq 'pubkeyhash'
      expect(outputs[3].output_type).to eq 'pubkeyhash'
      expect(outputs[4].output_type).to eq 'pubkeyhash'
    end

  end

  describe 'addresses' do
    let(:tx){ Bitcoin::Tx.parse_from_payload("01000000016b472242879ad9b16b021f4eec60bb77a3d37ff373c0c9b2d6df3a303a198b1b000000006a47304402204e9e2fa9b258a13b815b527bcc95a49f1bc85e2782eda3b640b0b1bb3f0f187502203e48358d3616f8589858732da32b14b25beb8a9d4033462c915b221b8d971105012102726d81fa11f16aaaecaf560ee7a6f12772385c567af1978e4bffef339264d1f3ffffffff05b8020e00000000001976a914fa66cdd02c487d2df74b90bc082606027594e50d88ac78500000000000001976a91413bf31e7504658854a2eeb26dce7e81765a8225f88ac78500000000000001976a9143af55380c66112c4d7e8cdc2ecc208ed09dbe8da88ac78500000000000001976a91464bf38d4f93c3353b2acdcc3580238ffbd53d05c88ac0000000000000000676a4c644f41010004000101015a753d68747470733a2f2f636f6e677265636861696e2d736161732d64656d6f2e73332d61702d6e6f727468656173742d312e616d617a6f6e6177732e636f6d2f70726f64756374696f6e2f70726f6a6563742f32342e6a736f6e00000000".htb) }

    before do
      BlockGraph::Model::Transaction.create_from_tx(tx, 0)
      Bitcoin.chain_params = :regtest
    end

    it 'should return bitcoin addresses' do
      outputs = BlockGraph::Model::Transaction.find_by(txid: tx.txid).outputs.order(n: :asc)

      expect(outputs[0].addresses).to eq ({address: ['n4LxNxPg2an9nZGDBYeqtMjnLTYi9zNKoZ']})
      expect(outputs[1].addresses).to eq ({address: ['mhKNB9zUH1gao8skwRBxyiFuW5aWAo6XWG']})
      expect(outputs[2].addresses).to eq ({address: ['mkthNk1D28HXLA4pQ7QAGy4iJaU54HKfQo']})
      expect(outputs[3].addresses).to eq ({address: ['mphewaGy5szgoM56Bz6YBAKMsNYFMUkEVj']})
      expect(outputs[4].addresses).to eq ({address: []})
    end
  end
end
