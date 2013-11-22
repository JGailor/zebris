module Zebris
  module Types
    class GenericConverter
      attr_reader :serializer, :deserializer

      def initialize(serializer, deserializer)
        @serializer = serializer
        @deserializer = deserializer
      end
    end

    class BasicObject
      def self.b(val)
        puts val
        val
      end

      def self.deserialize(value)
        value
      end

      def self.serialize(value)
        value
      end
    end

    class Date
      def self.deserialize(date)
        ::Date.parse(date)
      end

      def self.serialize(val)
        val.rfc3339
      end
    end

    class Integer
      def self.deserialize(val)
        (val && val != "") ? val.to_i : nil
      end

      def self.serialize(val)
        val
      end
    end

    class Float
      def self.deserialize(val)
        (val && val != "") ? val.to_f : nil
      end

      def self.serialize(val)
        val
      end
    end
  end
end