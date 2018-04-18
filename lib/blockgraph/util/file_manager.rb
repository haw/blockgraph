module BlockGraph
  module Util
    class FileManager

      attr_reader :data
      attr_reader :node_file
      attr_reader :rel_file
      attr_reader :dir

      def initialize(file_name, **opt)
        @node_file = file_name + ".csv"
        @rel_file = file_name + "_rel" + ".csv"
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
    end
  end
end