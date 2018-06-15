require 'blockgraph/version'
require 'bitcoin'
require 'parallel'
require 'neo4j'
require 'neo4j/core/cypher_session/adaptors/http'
require 'blockgraph/railtie' if defined?(Rails)

module BlockGraph
  autoload :CLI, 'blockgraph/cli'
  autoload :Migration, 'blockgraph/migration'

  autoload :Configuration, 'blockgraph/configuration'
  autoload :Model, 'blockgraph/model'
  autoload :Parser, 'blockgraph/parser'
  autoload :Util, 'blockgraph/util'
  autoload :OpenAssets, 'blockgraph/open_assets'
  autoload :Constants, 'blockgraph/constants'

  def self.configuration
    @configuration ||= BlockGraph::Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end

  Neo4j::Config[:association_model_namespace] = BlockGraph::Model
end
