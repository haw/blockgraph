require 'spec_helper'

RSpec.describe BlockGraph::GraphDB do

  describe 'configuration' do

    context 'default configuration' do
      subject { BlockGraph::GraphDB::Configuration.new }

      it 'should set config' do
        expect(subject.neo4j_server).to eq 'http://localhost:7474'
      end
    end

  end

end
