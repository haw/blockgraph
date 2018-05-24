require 'spec_helper'

RSpec.describe BlockGraph::Parser::ChainIndex do
  describe '#max_block_file_num' do
    subject {BlockGraph::Parser::ChainIndex.new(test_configuration)}
    it 'should return existing block file count' do
      expect(subject.send(:max_block_file_num, 0)).to eq(0)
    end
  end

  describe '#update' do
    context 'load file' do
      subject {
        index = BlockGraph::Parser::ChainIndex.new(test_configuration)
        index.update
        index.reorg_blocks
        index
      }
      it 'should parse block' do
        expect(subject.newest_block.block_hash).to eq('281dcd1e9124deef18140b754eab0550c46d6bd55e815415266c89d8faaf1f2d'.rhex)
        expect(subject.newest_block.tx_count).to eq(4)
        expect(subject.newest_block.input_count).to eq(3) # not count coinbase
        expect(subject.newest_block.output_count).to eq(8)
        expect(subject.newest_block.size).to eq(870)
        expect(subject.newest_block.file_num).to eq(0)
        expect(subject.newest_block.height).to eq(102)
      end
    end

  end

  describe '#parse_from_neo4j' do
    before do
      index = BlockGraph::Parser::ChainIndex.new(test_configuration)
      index.update
      index.reorg_blocks
      index.blocks_to_add.each do |block|
        BlockGraph::Model::BlockHeader.create_from_blocks(block)
      end
    end

    it 'should restore objects' do
      index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(test_configuration, tx: true)
      expect(index.newest_block.block_hash).to eq('281dcd1e9124deef18140b754eab0550c46d6bd55e815415266c89d8faaf1f2d'.rhex)
      expect(index.newest_block.tx_count).to eq(4)
      expect(index.newest_block.input_count).to eq(3) # not count coinbase
      expect(index.newest_block.output_count).to eq(8)
      expect(index.newest_block.size).to eq(870)
      expect(index.newest_block.file_num).to eq(0)
      expect(index.newest_block.height).to eq(102)
      txes = index.newest_block.transactions
      expect(txes.length).to eq(4)
      expect(txes[-1].txid).to eq('4dbea7be72e12f0c71634211c035cc800dc7aefe02994d6e97761cf817ae52b7')
      expect(txes[-1].version).to eq(2)
      expect(txes[-1].lock_time).to eq(101)
      expect(txes[-1].inputs.length).to eq(1)
      expect(txes[-1].outputs.length).to eq(2)
    end
  end
end
