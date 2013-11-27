require 'json'

module Zebris
  module Serializers
    class JSON
      class << self
        def serialize(data)
          data.to_json
        end

        def deserialize(stored)
          ::JSON.parse(stored)
        end
      end
    end
  end
end