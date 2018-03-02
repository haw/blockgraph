require 'active_support/all'

module BlockGraph

  class Migration

    attr_reader :sleep_interval

    def initialize(config)
      BlockGraph::GraphDB.configure do |c|
        c.neo4j_server = config[:neo4j][:server]
        c.extensions = config[:extensions] unless config[:extensions].nil?
      end
      neo4j_config = {basic_auth: config[:neo4j][:basic_auth], initialize: neo4j_timeout_ops(config)}
      configuration = BlockGraph::GraphDB::Parser::Configuration.new(config[:bitcoin][:out_dir], config[:bitcoin][:coin_dir])
      Neo4j::Session.open(:server_db, config[:neo4j][:server], neo4j_config)
      @sleep_interval = config[:bitcoin][:sleep_interval].nil? ? 600 :  config[:bitcoin][:sleep_interval].to_i

    end

    

    private

    def neo4j_timeout_ops(config)
       config[:neo4j][:initialize] ? config[:neo4j][:initialize] : {request: {timeout: 600, open_timeout: 2}}
    end
  end
end
