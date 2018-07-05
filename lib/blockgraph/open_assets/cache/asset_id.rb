module BlockGraph
  module OpenAssets
    module Cache

      class AssetId < BlockGraph::Cache::SQLiteBase

        def initialize(path = ':memory:')
          super(path)
        end

        def setup
          db.execute <<-SQL
            CREATE TABLE IF NOT EXISTS asset_ids(
            txid TEXT,
            n INTEGER,
            asset_id TEXT
            )
          SQL
        end

        # Return the subject value which defined by invalid url.
        # @param[String] txid The txid is a key of cache for fetch asset id.
        def get(txid, n)
          rows = db.execute('SELECT asset_id FROM asset_ids WHERE txid = ? AND n = ?', txid, n)
          return nil if rows.empty?
          rows.flatten[0]
        end

        # Saves a serialized transaction in cache.
        # @param[String] txid The txid is a key of cache for fetch asset id.
        # @param[String] asset_id The asset_id is should be returned asset id.
        def put(txid, n, asset_id)
          rows = db.execute('SELECT asset_id FROM asset_ids WHERE txid = ? AND n = ? AND asset_id = ?', txid, n, asset_id)
          db.execute('INSERT INTO asset_ids (txid, n, asset_id) VALUES (?, ?, ?)', [txid, n, asset_id]) if rows.empty?
        end

      end

    end
  end
end
