require 'spec_helper'

RSpec.describe BlockGraph::Model::BlockHeader do
  describe 'create_from_block_height' do
    before do
      config = YAML.load_file(File.join(File.dirname(__FILE__), "/../../fixtures/default_config.yml")).deep_symbolize_keys
      config = config[:blockgraph]
      neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(config[:neo4j][:server], {basic_auth: config[:neo4j][:basic_auth], initialize: {request: {timeout: 600, open_timeout: 2}}})
      Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }
    end

    subject(:blocks) {
      index = BlockGraph::Parser::ChainIndex.new(test_configuration)
      index.load
      index.blocks_to_add
    }

    subject(:added_blocks) {
      index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(test_configuration)
      index.load
      index.blocks_to_add
    }

    it 'should create block.' do
      expect{
        BlockGraph::Model::BlockHeader.create_from_blocks(blocks)
      }.to change{BlockGraph::Model::BlockHeader.count}.by(103) # include genesis block
    end

    it 'should set previous block' do
      BlockGraph::Model::BlockHeader.create_from_blocks(blocks)
      expect(BlockGraph::Model::BlockHeader.latest.first.previous_block.height).to eq 101
    end

    it 'should create new block. when some block header exist.' do
      BlockGraph::Model::BlockHeader.create_from_blocks(blocks)
      expect{
        BlockGraph::Model::BlockHeader.create_from_blocks(added_blocks)
      }.to change{BlockGraph::Model::BlockHeader.count}.by(0)
    end

    it 'should set property' do
      BlockGraph::Model::BlockHeader.create_from_blocks(blocks)
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
  end

end
