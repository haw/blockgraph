module BlockGraph
  module Parser
    class BlockParser

      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
      end

      def update_chain(max_block_height)
        chain_index = BlockGraph::Parser::ChainIndex.parse_from_neo4j(configuration)
        chain_index.update
        blocks = chain_index.generate_chain(max_block_height)
        blocks
      end

    end
  end
end
