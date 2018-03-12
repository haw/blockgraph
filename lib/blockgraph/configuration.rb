module BlockGraph
  class Configuration

    attr_accessor :neo4j_server

    def initialize
      @neo4j_server = 'http://localhost:7474'
    end

  end
end
