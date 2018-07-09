module BlockGraph
  module OpenAssets
    module Cache

      class ColoredOutput < BlockGraph::Cache::SQLiteBase

        def initialize(path = ':memory:')
          super(path)
        end

        def setup
          db.execute <<-SQL
            CREATE TABLE IF NOT EXISTS colored_outputs(
            txid TEXT,
            value INTEGER,
            n INTEGER,
            script TEXT,
            asset_id TEXT,
            asset_quantity INTEGER,
            output_type INTEGER,
            UNIQUE (txid, n)
            )
          SQL
        end

        # Return the subject value which defined by invalid url.
        # @param[String] txid The txid is a key of cache for fetch asset id.
        def get(txid)
          ret = []
          db.execute('SELECT value, script, asset_id, asset_quantity, output_type FROM colored_outputs WHERE txid = ? ORDER BY n ASC', txid) do |row|
            ret << BlockGraph::OpenAssets::Model::ColoredOutput.new(row[0], Bitcoin::Script.parse_from_payload(row[1]), row[2], row[3], row[4])
          end
          ret
        end

        def get_output(txid, n)
          db.execute('SELECT value, script, asset_id, asset_quantity, output_type FROM colored_outputs WHERE txid = ? AND n = ? ORDER BY n ASC LIMIT 1', txid, n) do |row|
            return BlockGraph::OpenAssets::Model::ColoredOutput.new(row[0], Bitcoin::Script.parse_from_payload(row[1]), row[2], row[3], row[4])
          end
          return []
        end

        # Saves a serialized transaction in cache.
        # @param[String] txid The txid is a key of cache for fetch asset id.
        # @param[String] asset_id The asset_id is should be returned asset id.
        def put(txid, outputs)
          begin
            db.transaction do
              outputs.each_with_index do |out, n|
                db.execute('REPLACE INTO colored_outputs (txid, n, value, script, asset_id, asset_quantity, output_type) VALUES (?, ?, ?, ?, ?, ?, ?)', [txid, n, out.value, out.script.to_payload, out.asset_id, out.asset_quantity, out.output_type])
              end
            end
          rescue SQLite3::ConstraintException => e
            return []
          end
        end

        def delete_all
          db.execute('DELETE FROM colored_outputs')
        end

      end

    end
  end
end
