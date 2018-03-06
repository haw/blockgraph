require 'thor'
require 'base'
require 'json'
require 'daemon_spawn'

module BlockGraph
  class BlockGraphDaemon < DaemonSpawn::Base

    def start(args)
      puts "BlockGraphDaemon start : #{Time.now}"
      migration = BlockGraph::Migration.new(args[0][:blockgraph])
      migration.run
    end

    def stop
      puts "BlockGraphDaemon stop : #{Time.now}"
    end

  end

  class CLI < Thor

    class_option :pid, aliases: '-p', default: Dir.pwd + '/blockgraph.pid', banner: '<pid file path>'
    class_option :log, aliases: '-l', default: Dir.pwd + '/blockgraph.log', banner: '<log file path>'

    option :conf, aliases: '-c' , required: true, banner: '<configuration file path>'

    desc "start", "start blockgraph daemon process"
    def start
      conf = read_conf options[:conf]
      execute_daemon(options[:log], options[:pid], ['start', conf])
    end

    desc "stop", "stop blockgraph daemon process"
    def stop
      execute_daemon(options[:log], options[:pid], ['stop'])
    end

    desc "status", "show blockgraph daemon status"
    def status
      execute_daemon(options[:log], options[:pid], ['status'])
    end

    option :conf, aliases: '-c', required: true, banner: '<configuration file path>'
    desc "restart", "restart blockgraph daemon process"
    def restart
      conf = read_conf options[:conf]
      execute_daemon(options[:log], options[:pid], ['restart', conf])
    end

    private
    def read_conf(conf_path)
      unless File.exists?(conf_path)
        raise ArgumentError.new(
            "configuration file[#{options[:conf]}] not specified or does not exist.")
      end
      YAML.load( File.read(options[:conf]) ).deep_symbolize_keys
    end

    def execute_daemon(log, pid, cmd_args)
      BlockGraph::BlockGraphDaemon.spawn!(
          { working_dir: Dir.pwd,
            log_file: File.expand_path(log),
            pid_file: File.expand_path(pid),
            sync_log: true,
            singleton: true},
          cmd_args)
    end
  end
end
