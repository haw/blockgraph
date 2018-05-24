require 'spec_helper'

RSpec.describe BlockGraph::Model::BlockHeader do
  describe 'create_from_block_height' do
    subject(:blocks) {
      index = BlockGraph::Parser::ChainIndex.new(test_configuration)
      index.update
      index.blocks_to_add
    }

    subject(:added_blocks) {
      index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(test_configuration)
      index.update
      index.blocks_to_add
    }

    before do
      blocks.each do |block|
        BlockGraph::Model::BlockHeader.create_from_blocks(block)
      end
    end

    it 'should create block.' do
      expect(BlockGraph::Model::BlockHeader.count).to eq (103) # include genesis block
    end

    it 'should set previous block' do
      expect(BlockGraph::Model::BlockHeader.latest.first.previous_block.height).to eq 101
    end

    it 'should create new block. when some block header exist.' do
      expect{
        added_blocks.each do |block|
          BlockGraph::Model::BlockHeader.create_from_blocks(block)
        end
      }.to change{BlockGraph::Model::BlockHeader.count}.by(0)
    end

    it 'should set property' do
      block = BlockGraph::Model::BlockHeader.latest.first
      expect(block.block_hash).to eq '281dcd1e9124deef18140b754eab0550c46d6bd55e815415266c89d8faaf1f2d'.rhex
      expect(block.version).to eq 536870912
      expect(block.previous_block.block_hash.rhex).to eq '3c08bd4584e4c18d19eaacc7fd8d4dc43f37e0f8baa364995e4ebf0594298699'
      expect(block.merkle_root).to eq '47a9de476c5d1be5d593b7078c29e31a3e3e4f0381a94664e3aebf4e8b24da54'.rhex
      expect(block.time).to eq 1517461474
      expect(block.bits).to eq '207fffff'.to_i(16)
      expect(block.nonce).to eq 0
      expect(block.file_num).to eq 0
      expect(block.height).to eq 102
      expect(block.size).to eq 870
      expect(block.tx_num).to eq 4
      expect(block.input_num).to eq 3
      expect(block.output_num).to eq 8
    end

    it 'should set transactions' do
      block = BlockGraph::Model::BlockHeader.latest.first
      expect(block.transactions.count).to eq block.tx_num
      expect(block.transactions).to contain_exactly(
                                                     have_attributes(txid: '30a1883603b50cae28dcf3f3b235d14c446c42088f9bbf6515e64d13d40235a2'),
                                                     have_attributes(txid: 'a7296d4e31cd08cc52f51280bf9b88e1da5a6becf5a7a504c7929d55d8a98a13'),
                                                     have_attributes(txid: 'c3aecbcad8f901dbb501f00be072afb7df8321b86b608f8afc55d76e207742a2'),
                                                     have_attributes(txid: '4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7')
                                                 )
      expect(block.transactions).to contain_exactly(
                                        have_attributes(version: 2),
                                        have_attributes(version: 2),
                                        have_attributes(version: 2),
                                        have_attributes(version: 2)
                                        )
      expect(block.transactions).to contain_exactly(
                                        have_attributes(lock_time: 0),
                                        have_attributes(lock_time: 101),
                                        have_attributes(lock_time: 101),
                                        have_attributes(lock_time: 101)
                                        )
      target = block.transactions.find{|tx| tx.txid == '4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7'}
      expect(target.txid).to eq '4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7'
      expect(target.inputs.length).to eq 1
      expect(target.inputs[0].txid).to eq 'a7296d4e31cd08cc52f51280bf9b88e1da5a6becf5a7a504c7929d55d8a98a13'
      expect(target.outputs.length).to eq 2
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
      it 'should be imported block header nodes by csv' do
        BlockGraph::Model::BlockHeader.import_node(0)
        expect(BlockGraph::Model::BlockHeader.count).to eq 103
        expect(BlockGraph::Model::BlockHeader.latest[0].previous_block).to eq nil
      end
    end

    context 'import node with relation' do
      it 'should be imported block header nodes and relations by csv' do
        BlockGraph::Model::BlockHeader.import_node(0)
        BlockGraph::Model::BlockHeader.import_rel(0)
        expect(BlockGraph::Model::BlockHeader.count).to eq 103
        expect(BlockGraph::Model::BlockHeader.latest[0].previous_block).to_not eq nil
      end
    end
  end

end
