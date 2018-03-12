module BlockGraph
  class Configuration

    include BlockGraph::Model::Extensions

    attr_accessor :neo4j_server

    def initialize
      @extensions = []
      @neo4j_server = 'http://localhost:7474'
    end

  end
end
