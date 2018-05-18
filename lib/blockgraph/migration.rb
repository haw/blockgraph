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

    def run_with_height(max_block_height = 0)
      puts "coming soon start migration. #{Time.now}"
      blocks = parser.update_chain(max_block_height)
      extr = BlockGraph::Util::Extracter.new
      extr.export(blocks)
      BlockGraph::Model::BlockHeader.import("block_headers")
      BlockGraph::Model::Transaction.import("transactions")

    def export
      loop {
        begin
          blocks = parser.update_chain(0)
          extr = BlockGraph::Util::Extracter.new
          extr.export(blocks)
        rescue BlockGraph::Parser::Error => e
          if e.message == '{"code"=>-8, "message"=>"Block height out of range"}'
            puts "All blocks export finished"
            return
          else
            raise e
          end
        end
      }
    end

    def import_batch
      loop {
        begin
          blocks = parser.update_chain(0)
          extr = BlockGraph::Util::Extracter.new
          extr.export(blocks)
          import(max_csv_file_num("block"))
        rescue BlockGraph::Parser::Error => e
          if e.message == '{"code"=>-8, "message"=>"Block height out of range"}'
            puts "All blocks export finished"
            return
          else
            raise e
          end
        end
      }
    end

    def import(start_num = 0)
      file_num = start_num
      file_count = max_csv_file_num("block") - file_num + 1
      file_count.times do |i|
        puts "import #{file_name_with_num("block", file_num + i)}.csv"
        BlockGraph::Model::BlockHeader.import(file_name_with_num("block", file_num + i))
        BlockGraph::Model::Transaction.import(file_name_with_num("tx", file_num + i))
      end
      puts 'import finished'
    end

    private

    def neo4j_timeout_ops(config)
       config[:neo4j][:initialize] ? config[:neo4j][:initialize] : {request: {timeout: 600, open_timeout: 2}}
    end

    def file_name_with_num(file_name, num)
      file_name + num.to_s.rjust(5, '0')
    end

    def max_csv_file_num(file_name, start_file = 0)
      file_num = start_file
      while File.exist?(File.join(neo4j_import_dir, file_name) + file_num.to_s.rjust(5, '0') + '.csv')
        file_num += 1
      end
      file_num - 1
    end

    def neo4j_import_dir
      BlockGraph::Util::FileManager.new.dir[0]
    end
  end
end
