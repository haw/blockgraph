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

    # TODO use RPC import
    def run
      loop {
        begin
          run_with_height
        rescue BlockGraph::Parser::Error => e
          if e.message == '{"code"=>-8, "message"=>"Block height out of range"}'
            puts "Block height out of range. sleep #{@sleep_interval} seconds."
            sleep @sleep_interval
          else
            raise e
          end
        end
      }
    end

    # TODO use RPC import
    def run_with_height(max_block_height = 0)
      puts "coming soon start migration. #{Time.now}"
      blocks = parser.update_chain
      extr = BlockGraph::Util::Extractor.new
      extr.export(blocks)
      BlockGraph::Model::BlockHeader.import("block_headers")
      BlockGraph::Model::Transaction.import("transactions")
      puts
      puts "end migration for block height #{blocks[-1].height}. #{Time.now}"
    end

    def export
      blocks = parser.update_chain
      extr = BlockGraph::Util::Extractor.new
      extr.export(blocks)
    end

    def import_batch
      loop {
        begin
          blocks = parser.update_chain
          extr = BlockGraph::Util::Extractor.new
          extr.export(blocks)
          import_with_relation(max_csv_file_num("block"))
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
        BlockGraph::Model::BlockHeader.import_node(file_num + i)
        BlockGraph::Model::Transaction.import_node(file_num + i)
        BlockGraph::Model::TxOut.import_node(file_num + i)
        BlockGraph::Model::TxIn.import_node(file_num + i)
      end

      puts 'import finished'
    end

    def import_with_relation(start_num = 0)
      file_num = start_num
      import(file_num)
      (max_csv_file_num("block") + 1).times do |i|
        BlockGraph::Model::BlockHeader.import_rel(i)
        BlockGraph::Model::Transaction.import_rel(i)
        BlockGraph::Model::TxOut.import_rel(i)
        BlockGraph::Model::TxIn.import_rel(i)
      end

      puts 'import finished'
    end

    def update_height
      blocks = parser.update_height
      extr = BlockGraph::Util::Extractor.new
      extr.export_update(blocks)
      BlockGraph::Model::BlockHeader.update

      puts 'block height has updated'
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
