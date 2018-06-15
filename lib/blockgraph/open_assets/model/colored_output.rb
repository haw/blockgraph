module BlockGraph
  module OpenAssets
    module Model
      class ColoredOutput

        attr_accessor :value
        attr_accessor :script
        attr_accessor :asset_id
        attr_accessor :asset_quantity
        attr_accessor :output_type

        attr_accessor :account
        attr_accessor :metadata
        attr_accessor :asset_definition_url
        attr_accessor :asset_definition

        alias :script_pubkey :script
        
        def initialize(value, script, asset_id = nil, asset_quantity = 0, output_type = BlockGraph::Constants::OutputType::UNCOLORED, metadata = '')
          raise ArgumentError, "invalid output_type : #{output_type}" unless BlockGraph::Constants::OutputType.all.include?(output_type)
          raise ArgumentError, "invalid asset_quantity. asset_quantity should be unsignd integer. " unless asset_quantity.between?(0, 2 ** 63 -1)
          @value = value
          @script = script
          @asset_id = asset_id
          @asset_quantity = asset_quantity
          @output_type = output_type
          @metadata = metadata
          load_asset_definition_url
        end

        def value_to_btc
          "%.8f" % (value / 100000000.0)
        end

        private
        @@definition_cache = {}

        # get Asset definition url that is included metadata.
        def load_asset_definition_url
          @asset_definition_url = ''
          return if @metadata.nil? || @metadata.length == 0
          if @metadata.start_with?('u=')
            @asset_definition = load_asset_definition(metadata_url)
            if valid_asset_definition?
              @asset_definition_url = metadata_url
            else
              @asset_definition_url = "The asset definition is invalid. #{metadata_url}"
            end
          else
            @asset_definition_url = 'Invalid metadata format.'
          end
        end

        def metadata_url
          unless @metadata.nil?
            @metadata.slice(2..-1)
          end
        end

        def valid_asset_definition?
          !@asset_definition.nil? && @asset_definition.include_asset_id?(@asset_id)
        end

        def load_asset_definition(url)
          unless @@definition_cache.has_key?(url)
            if metadata_url.start_with?('http://') || metadata_url.start_with?('https://')
              begin
                definition = AssetDefinition.parse_json(RestClient::Request.execute(:method => :get, :url => metadata_url, :timeout => 10, :open_timeout => 10))
                definition.asset_definition_url = metadata_url
                @@definition_cache[url] = definition
              rescue => e
                puts e
                @@definition_cache[url] = nil
              end
            end
          end
          @@definition_cache[url]
        end
      end

    end
  end
end
