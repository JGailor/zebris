module Zebris
  module Types
    class RedisDate
      def self.parse(date)
        Date.parse(date)
      end
    end

    class RedisInteger
      def self.parse(val)
        (val && val != "") ? val.to_i : nil
      end
    end

    class RedisFloat
      def self.parse(val)
        (val && val != "") ? val.to_f : nil
      end
    end

    class RedisString
      def self.parse(val)
        val ? val.to_s : nil
      end
    end
  end
end