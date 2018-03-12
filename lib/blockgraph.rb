require 'blockgraph/version'
require 'bitcoin'
require 'parallel'
require 'neo4j'
require 'neo4j/core/cypher_session/adaptors/http'

module BlockGraph
  autoload :CLI, 'blockgraph/cli'
  autoload :Configuration, 'blockgraph/configuration'

  def self.configuration
    @configuration ||= BlockGraph::Configuration.new
  end

end
