require 'date'
require 'time'

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
        raise "#{val} not a valid Date" unless val.respond_to?(:to_time)

        Time.serialize(val.to_time)
      end
    end

    class Time
      def self.deserialize(time)
        ::Time.parse(date)
      end

      def self.serialize(val)
        raise "#{val} not a valid Time" unless val.kind_of?(::Time)
        val.to_time.rfc2822
      end
    end

    class DateTime
      def self.deserialize(date)
        ::DateTime.parse(date)
      end

      def self.serialize(val)
        raise "#{val} not a valid DateTime" unless val.respond_to?(:to_time)

        Time.serialize(val.to_time)
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