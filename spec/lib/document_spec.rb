require_relative "../../lib/zebris"
require 'uuid'

describe Zebris::Document do
  class Document
    include Zebris::Document
    key {UUID.generate}
    property :name, RedisString
    property :age, RedisInteger
    property :last_update, RedisDate
  end

  class LambdaDocument
    include Zebris::Document
    key {UUID.generate}
    property :name, lambda {|n| n}, lambda {|n| String.new(n)}
  end

  class NestedDocument
    include Zebris::Document
    key {UUID.generate}
    property :person, Person

    class Person
      include Zebris::Document
      key {UUID.generate}
      property :name, RedisString
      property :age, RedisInteger
    end
  end

  let!(:redis)      {double(:redis, set: true, get: true)}
  let(:key)         {"ABCDEFG"}
  let(:name)        {"John Henry"}
  let(:age)         {34}
  let(:last_update) {Date.today - 2}

  before do
    Zebris.redis = redis
  end

  context "saving documents" do
    it "should persist a document with a name property" do
      document = Document.new
      document.stub(:key).and_return(key)
      redis.should_receive(:set).with(key, {"key" => key, "name" => name}.to_json)

      document.name = name
      document.save
    end

    context "property types" do
      it "properly serializes the built in types" do
        document = Document.new
        document.stub(:key).and_return(key)
        redis.should_receive(:set).with(key, {"key" => key, "name" => name, "age" => age, "last_update" => last_update.rfc3339}.to_json)

        document.name = name
        document.age = age
        document.last_update = last_update
        document.save
      end

      it "properly serializes the data when given a lambda" do
        document = LambdaDocument.new
        document.stub(:key).and_return(key)
        redis.should_receive(:set).with(key, {"key" => key, "name" => name}.to_json)

        document.name = name
        document.save
      end

      context "nested type collections" do
        it "serializes nested types if they include Zebris::Document" do
          expect {
            document = NestedDocument.new
            document.person = NestedDocument::Person.new
            document.person.name = name
            document.person.age = age
            document.save
          }.to_not raise_exception
        end

        it "raises an exception if you attempt to declare a collection of things that aren't Zebris::Document" do
          class BadDocument
            include Zebris::Document

            key {"This is a horrible key"}

            property :person, Object
          end

          expect {
            document = BadDocument.new
            document.person = Object.new
            document.save
          }.to raise_exception
        end
      end
    end
  end
end