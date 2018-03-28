require "bundler/setup"
require "base"
require "neo4j"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # for thor command.
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end

  config.before(:each) do |example|
    unless example.metadata[:cli]
      BlockGraph.configuration
      neo4j_session
      Neo4j::ActiveBase.current_session.query('MATCH(n) DETACH DELETE n')
    end
  end

  config.after(:each) do |example|
    if example.metadata[:cli]
      Dir.glob(["*.pid", "*.log"]).each do |f|
        File.delete f
      end
    else
      Neo4j::ActiveBase.current_session.query('MATCH(n) DETACH DELETE n')
    end
  end

  def test_configuration
    BlockGraph::Parser::Configuration.new("#{Dir.tmpdir}/blockgraph", File.join(File.dirname(__FILE__), 'fixtures/regtest'))
  end

  def neo4j_session
    config = YAML.load_file(File.join(File.dirname(__FILE__), "fixtures/default_config.yml")).deep_symbolize_keys
    config = config[:blockgraph]
    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(config[:neo4j][:server], {basic_auth: config[:neo4j][:basic_auth], initialize: {request: {timeout: 600, open_timeout: 2}}})
    Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }
  end
end
