require 'blockgraph/version'
require 'bitcoin'
require 'parallel'
require 'neo4j'
require 'neo4j/core/cypher_session/adaptors/http'

module BlockGraph
  autoload :CLI, 'blockgraph/cli'
  autoload :Migration, 'blockgraph/migration'

  autoload :Configuration, 'blockgraph/configuration'
  autoload :Model, 'blockgraph/model'
  autoload :Parser, 'blockgraph/parser'
  autoload :Util, 'blockgraph/util'

  def self.configuration
    @configuration ||= BlockGraph::Configuration.new
  end

  def self.configure
    yield configuration if block_given?
    # configuration.load_extensions
  end

  Neo4j::Config[:association_model_namespace] = BlockGraph::Model
end
