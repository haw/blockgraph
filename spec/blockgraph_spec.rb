RSpec.describe BlockGraph do
  it "has a version number" do
    expect(BlockGraph::VERSION).not_to be nil
  end

  describe 'configuration' do

    context 'default configuration' do
      subject { BlockGraph::Configuration.new }

      it 'should set config' do
        expect(subject.neo4j_server).to eq 'http://localhost:7474'
      end
    end

  end
end
