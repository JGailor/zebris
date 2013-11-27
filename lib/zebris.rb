require "zebris/version"
require "zebris/types"
require "zebris/document"
require "zebris/serializers/json"

module Zebris
  def self.redis=(connection)
    @redis = connection
  end

  def self.redis
    @redis
  end

  def self.serializer=(serializer)
    raise "Not a zebris serializer" unless serializer.name.start_with?("Zebris::Serializers")
    @serializer = serializer
  end

  def self.serializer
    @serializer ||= Zebris::Serializers::JSON
  end
end
