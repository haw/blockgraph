module BlockGraph
  module Parser
    class BlockParser

      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def update_chain(max_block_height)
        chain_index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(configuration)
      def update_chain
        # chain_index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(configuration)
        chain_index = BlockGraph::Parser::ChainIndex.new(configuration)
        chain_index.update
        blocks = chain_index.block_list.values
        raise BlockGraph::Parser::Error.new('{"code"=>-8, "message"=>"Block height out of range"}') if blocks.blank?
        blocks
      end

      def update_height
        chain_index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(configuration)
        chain_index.reorg_blocks
        blocks = chain_index.generate_chain(0)
        raise BlockGraph::Parser::Error.new('{"code"=>-8, "message"=>"Block height out of range"}') if blocks.blank?
        blocks
      end

    end
  end
end
