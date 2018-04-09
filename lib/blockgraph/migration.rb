require 'base'

module BlockGraph

  class Migration

    attr_reader :sleep_interval
    attr_reader :parser

    def initialize(config)
      BlockGraph.configure do |c|
        c.neo4j_server = config[:neo4j][:server]
        c.extensions = config[:extensions] unless config[:extensions].nil?
      end
      configuration = BlockGraph::Parser::Configuration.new(config[:bitcoin][:out_dir], config[:bitcoin][:coin_dir])
      @parser = BlockGraph::Parser::BlockParser.new(configuration)
      neo4j_config = {basic_auth: config[:neo4j][:basic_auth], initialize: neo4j_timeout_ops(config)}
      neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(config[:neo4j][:server], neo4j_config)
      Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }
      @sleep_interval = config[:bitcoin][:sleep_interval].nil? ? 600 :  config[:bitcoin][:sleep_interval].to_i

      BlockGraph::Model.constants.each {|const_name| BlockGraph::Model.const_get(const_name)}
    end

    def run
      loop {
        puts "coming soon start migration. #{Time.now}"
        begin
          blocks = parser.update_chain
          blocks.each do |block|
            puts "start migration for block height #{block.height}. #{Time.now}"
            Neo4j::ActiveBase.run_transaction do |tx|
              begin
                BlockGraph::Model::BlockHeader.create_from_blocks(block)
                @block_height = blocks[-1].height
              rescue => e
                tx.failure
                raise e
              end
            end
          end
        rescue BlockGraph::Parser::Error => e
          if e.message == '{"code"=>-8, "message"=>"Block height out of range"}'
            puts "Block height out of range. sleep #{@sleep_interval} seconds."
            sleep @sleep_interval
          else
            raise e
          end
        end
        puts
        puts "end migration for block height #{@block_height}. #{Time.now}"
      }
    end

    private

    def neo4j_timeout_ops(config)
       config[:neo4j][:initialize] ? config[:neo4j][:initialize] : {request: {timeout: 600, open_timeout: 2}}
    end
  end
end
