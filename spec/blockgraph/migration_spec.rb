require 'spec_helper'


RSpec.describe BlockGraph::Migration do

  describe 'load configuration' do
    context 'default configuration' do
      subject{
        config = YAML.load_file(File.join(File.dirname(__FILE__), "/../fixtures/default_config.yml")).deep_symbolize_keys
        BlockGraph::Migration.new(config[:blockgraph])
        BlockGraph.configuration
      }
      it do
        expect(subject.neo4j_server).to eq('http://localhost:7475')
        expect(subject.extensions).to be_empty
      end
    end
  end

end
