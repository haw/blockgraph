require 'csv'
module BlockGraph
  module Util
    class FileManager

      attr_reader :data
      attr_reader :node_file
      attr_reader :rel_file
      attr_reader :dir

      def initialize(**opt)
        @dir = opt[:dir]
        unless @dir
          neo4j_config = Neo4j::ActiveBase.current_session.query('CALL dbms.listConfig() yield name,value WHERE name=~"dbms.directories.import" RETURN value')
          @dir = neo4j_config.rows.first
        end
      end

      def path(file_name)
        File.join(dir, file_name)
      end

      def file_generate(name, head)
        CSV.open(path(name), "w", force_quotes: true) do |csv|
          csv << head
        end
      end

      def open(file_name, mode = "r")
        @node_file = CSV.open(path(file_name + ".csv"), mode, force_quotes: true)
        @rel_file = CSV.open(path(file_name + "_rel" + ".csv"), mode, force_quotes: true)
      end

      def flush
        node_file.flush
        rel_file.flush
      end

      def close
        node_file.close
        rel_file.close
      end

      def closed?
        node_file.closed? && rel_file.closed?
      end
    end
  end
end