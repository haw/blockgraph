module BlockGraph
  module Parser
    class BlockParser

      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def update_chain
        chain_index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(configuration)
        chain_index.load
        blocks = chain_index.blocks_to_add
        raise BlockGraph::Parser::Error.new('{"code"=>-8, "message"=>"Block height out of range"}') if blocks.blank?
        blocks
      end

    end
  end
end
