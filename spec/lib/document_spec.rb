require_relative "../../lib/zebris"
require 'uuid'

describe Zebris::Document do
  class Document
    include Zebris::Document
    key {UUID.generate}
    property :name, String
    property :age, Integer
    property :last_update, Date
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
      property :name, String
      property :age, Integer
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
          person_key = "123456"
          person = NestedDocument::Person.new
          person.name = name
          person.age = age
          person.stub(:key).and_return(person_key)

          redis.should_receive(:set).with(key, {"key" => key, "person" => {"key" => person_key, "name" => name, "age" => age}}.to_json)

          document = NestedDocument.new
          document.stub(:key).and_return(key)
          document.person = person
          document.save
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

  context "restoring documents" do
    let(:serialized_document) {{"key" => key, "name" => name}.to_json}
    let(:types_serialized_document) {{"key" => key, "name" => name, "age" => age, "last_update" => last_update.rfc3339}.to_json}
    let(:lambda_serialized_document) {{"key" => key, "name" => name}.to_json}
    let(:nested_serialized_document) {{"key" => key, "person" => {"name" => name, "age" => age}}.to_json}

    it "delegates to the redis object" do
      redis.should_receive(:get).with(key).and_return(serialized_document)
      Document.find(key)
    end

    it "rebuilds an object that has been saved to redis" do
      redis.stub(:get).and_return(serialized_document)
      document = Document.find(key)
      expect(document.name).to eq(name)
    end

    context "property types" do
      it "rebuilds an object using built-in types" do
        redis.stub(:get).and_return(types_serialized_document)
        document = Document.find(key)
        expect(document.name).to eq(name)
        expect(document.age).to eq(age)
        expect(document.last_update).to eq(last_update)
      end

      it "rebuilds an object using lambda serializers/deserializers" do
        redis.stub(:get).and_return(lambda_serialized_document)
        document = LambdaDocument.find(key)
        expect(document.name).to eq(name)
      end

      context "nested documents" do
        it "rebuilds a nested object structure" do
          redis.stub(:get).and_return(nested_serialized_document)
          document = NestedDocument.find(key)
          expect(document.person.name).to eq(name)
          expect(document.person.age).to eq(age)
        end
      end
    end
  end
end