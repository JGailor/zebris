require_relative '../../lib/zebris/types'
require 'date'

describe Zebris::Types do
  context Zebris::Types::RedisDate do
    it "deserializes a valid date" do
      d = Date.today
      expect(Zebris::Types::RedisDate.deserialize(d.to_s)).to eq(d)
    end

    it "raises an exception if the date is invalid" do
      d = ""
      expect{Zebris::Types::RedisDate.deserialize(d.to_s)}.to raise_exception
    end
  end

  context Zebris::Types::RedisInteger do
    it "deserializes a valid integer" do
      i = 101
      expect(Zebris::Types::RedisInteger.deserialize(i.to_s)).to eq(i)
    end

    it "returns nil if the integer is an empty string" do
      i = ""
      expect(Zebris::Types::RedisInteger.deserialize(i.to_s)).to eq(nil)
    end

    it "returns nil if the integer is nil" do
      i = nil
      expect(Zebris::Types::RedisInteger.deserialize(i)).to eq(nil)
    end

    it "raises an exception if the object does not support being converted to an integer" do
      o = Object.new
      expect{Zebris::Types::RedisInteger.deserialize(o)}.to raise_exception
    end
  end

  context Zebris::Types::RedisFloat do
    it "deserializes and returns serialized float" do
      f = 10.23
      expect(Zebris::Types::RedisFloat.deserialize(f.to_s)).to eq(f)
    end

    it "deserializes and returns nil on an empty string" do
      f = ""
      expect(Zebris::Types::RedisFloat.deserialize(f.to_s)).to eq(nil)
    end

    it "deserializes and returns nil on an empty string" do
      f = nil
      expect(Zebris::Types::RedisFloat.deserialize(f)).to eq(nil)
    end

    it "raises an exception if the object does not support being converted to a float" do
      o = Object.new
      expect{Zebris::Types::RedisFloat.deserialize(o)}.to raise_exception
    end
  end

  context Zebris::Types::RedisString do
    it "deserializes and returns a string as itself" do
      s = %q{Do the ham bone}
      expect(Zebris::Types::RedisString.deserialize(s)).to eq(s)
    end

    it "deserializes and returns nil as nil" do
      s = nil
      expect(Zebris::Types::RedisString.deserialize(s)).to eq(nil)
    end

    it "raises an exception if the object does not support being converted to a string" do
      o = BasicObject.new
      expect{Zebris::Types::RedisString.deserialize(o)}.to raise_exception
    end
  end
end