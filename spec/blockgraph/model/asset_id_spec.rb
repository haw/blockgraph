require 'spec_helper'

RSpec.describe BlockGraph::Model::AssetId do

  describe 'find_or_create' do

    let(:asset_id){ 'oZ6NmQgn8i3uF6VcmWVJgjT3qtGVyd7nci' }

    context 'find' do
      before do
        mock = double('AssetId')
        allow(mock).to receive(:asset_id).and_return(asset_id)
        allow(mock).to receive(:first).and_return(mock)
        allow(BlockGraph::Model::AssetId).to receive(:with_asset_id).and_return(mock)
      end

      it 'should return asset id' do
        expect(BlockGraph::Model::AssetId).to receive(:with_asset_id).with(asset_id)
        expect(BlockGraph::Model::AssetId.find_or_create(asset_id))
      end
    end

    context 'create' do
      it 'should create asset id' do
        expect(BlockGraph::Model::AssetId).to receive(:with_asset_id).with(asset_id).and_call_original
        expect{
          BlockGraph::Model::AssetId.find_or_create(asset_id)
        }.to change{ BlockGraph::Model::AssetId.count }.by(1)
      end
    end
  end

end
