require 'spec_helper'

RSpec.describe BlockGraph::Parser::ChainIndex do
  describe '#max_block_file_num' do
    subject {BlockGraph::Parser::ChainIndex.new(test_configuration)}
    it 'should return existing block file count' do
      expect(subject.send(:max_block_file_num, 0)).to eq(0)
    end
  end

  describe '#load' do
    context 'load file' do
      subject {
        index = BlockGraph::Parser::ChainIndex.new(test_configuration)
        index.load
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
  
end
