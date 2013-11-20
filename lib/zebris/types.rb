module Zebris
  module Types
    class GenericConverter
      attr_reader :serializer, :deserializer

      def initialize(serializer, deserializer)
        @serializer = serializer
        @deserializer = deserializer
      end
    end

    class RedisDate
      def self.deserialize(date)
        Date.parse(date)
      end

      def self.serialize(val)
        val.rfc3339
      end
    end

    class RedisInteger
      def self.deserialize(val)
        (val && val != "") ? val.to_i : nil
      end

      def self.serialize(val)
        val
      end
    end

    class RedisFloat
      def self.deserialize(val)
        (val && val != "") ? val.to_f : nil
      end

      def self.serialize(val)
        val
      end
    end

    class RedisString
      def self.deserialize(val)
        val ? val.to_s : nil
      end

      def self.serialize(val)
        val
      end
    end
  end
end