require 'base'

namespace :bg do
  desc 'Import specified block to neo4j database.'
  task :import, [:mode, :config_path] do |task, args|
    puts "import blocks."
    migration = get_migration(args.config_path)
    if args.mode.to_i == 0
      migration.run
    elsif args.mode.to_i == 1
      migration.import_batch
    end
  end

  desc 'Import specified block to neo4j database.'
  task :import_block, [:block_height,:config_path] do |task, args|
    puts "import #{args.block_height} block."
    get_migration(args.config_path).run_with_height(args.block_height.to_i)
  end

  desc 'Remove specified block from neo4j database.'
  task :remove_block, [:block_height,:config_path] do |task, args|
    puts "remove #{args.block_height} block."
    get_migration(args.config_path).remove_block(args.block_height.to_i)
  end

  desc 'Import specified transaction to neo4j database.'
  task :import_tx, [:txid,:config_path] do |task, args|
    get_migration(args.config_path).import_tx(args.txid)
  end

  desc 'Remove specified transaction from neo4j database.'
  task :remove_tx, [:txid,:config_path] do |task, args|
    get_migration(args.config_path).remove_tx(args.txid)
  end

  desc 'Repair specified transaction.'
  task :repair_tx, [:txid,:config_path] do |task, args|
    get_migration(args.config_path).remove_tx(args.txid)
    get_migration(args.config_path).import_tx(args.txid)
  end

  desc 'Remove down to block specified from the latest block'
  task :remove_until_block, [:block_height,:config_path] do |task, args|
    target_block_height = args.block_height.to_i
    puts "remove_until_block down to #{target_block_height}"
    migration = get_migration(args.config_path)
    current_height = BlockGraph::Model::BlockHeader.latest.first.height
    current_height.downto(target_block_height) do |height|
      migration.remove_block(height)
    end
  end

  desc 'Search invalid oa tx.(invalid tx exist only openassets-ruby bug.)'
  task :search_invalid_oa_tx, [:config_path] do |task, args|
    get_migration(args.config_path).search_invalid_oa_tx
  end

  desc 'Export csv files converted raw data'
  task :export, [:config_path] do |task, args|
    get_migration(args.config_path).export
  end

  desc 'Import csv files'
  task :import_csv, [:start_num, :config_path] do |task, args|
    get_migration(args.config_path).import_with_relation(args.start_num.to_i)
  end

  desc 'Import csv file for updating block height after calculate block height'
  task :update_height, [:config_path] do |task, args|
    get_migration(args.config_path).update_height
  end

  private
  def get_migration(config_path)
    config = YAML.load(File.read(config_path)).deep_symbolize_keys[:blockgraph]
    BlockGraph::Migration.new(config)
  end
end
