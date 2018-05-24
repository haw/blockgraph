require 'spec_helper'

RSpec.describe BlockGraph::Util::Extractor do
  describe 'export' do
    subject(:blocks) {
      index = BlockGraph::Parser::ChainIndex.new(test_configuration)
      index.update
      index.reorg_blocks
      index.generate_chain(0)
    }

    before do
      FileUtils.rm_rf(neo4j_dir, :secure => true)
      FileUtils.mkdir(neo4j_dir)
    end

    after do
      FileUtils.rm_rf(neo4j_dir, :secure => true)
      FileUtils.mkdir(neo4j_dir)
    end

    it 'should export csv in $NEO4J_HOME' do
      extr = BlockGraph::Util::Extractor.new
      extr.export(blocks)
      expect(File.exists?(File.join(neo4j_dir, "block00000.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "block00000_rel.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx00000.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx00000_rel.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx_inputs00000.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx_inputs00000_rel.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx_outputs00000.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx_outputs00000_large.csv"))).to be_truthy
      expect(File.exists?(File.join(neo4j_dir, "tx_outputs00000_rel.csv"))).to be_truthy
    end
  end
end
