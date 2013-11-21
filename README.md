[![Gem Version](https://badge.fury.io/rb/zebris.png)](http://badge.fury.io/rb/zebris)
[![Build Status](https://travis-ci.org/JGailor/zebris.png?branch=master)](https://travis-ci.org/JGailor/zebris)

# Zebris

Zebris is built to allow you to add persisting and retrieving your objects to and from Redis with a minimum of hassle or re-writing of your code.
When I needed a library to do something similar, I noticed that a lot of the other Redis persistence libraries were very opinionated or tried to
implement the ActiveRecord pattern, which is nice but would have required me to re-write a lot more of my code to conform to the libraries idioms
than I wanted to do.  My goal was to make it as easy as possible to add a ruby gem to my project and with as little code as possible make it easy to
persist the object to Redis and retrieve it later.  Such is Zebris, or so I hope.

I welcome all feedback and suggestions on how to improve Zebris.  It's very young, but I have a roadmap in mind to add some things that I think will
allow Zebris to keep it's simplicity and general purpose use while adding a lot of utility for anyone using it.

## Installation

Add this line to your application's Gemfile:

    gem 'zebris'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zebris

## Usage

### Configuration
Zebris is happy to delegate to any Redis client that supports the 2.0+ command list.  To configure Zebris, just pass it a connected Redis client object:

    Zebris.redis = Redis.new

### Basic Document Peristence

    class Person
      include Zebris::Document

      key {UUID.generate}   # Or anything that will generate unique keys

      # String, Integer, Float, Date are built-in types to Zebris that understand
      # serialization and deserialization of those types
      property :name, String
      property :weight, Float
      property :lucky_number, Integer
      property :birthday, Date
    end

    person = Person.new
    person.name = "Tyler Durden"
    person.weight = 175.2
    person.lucky_number = 13
    person.birthday = Date.parse('1979-05-20')

    key = person.save
    => "some uuid here"

    tyler = Person.find(key)

    # Tyler is back

### Custom serialization/deserialization

    class WaterSample
      include Zebris::Document

      key {UUID.generate}   # Or anything that will generate unique keys

      # Redis likes strings, so you can provide a proc to serialize
      # and deserialize your data to/from strings if it doesn't fit
      # the built-in types
      property :subject, String
      property :time, lambda {|time| time.to_i.to_s}, lambda {|milli| Time.at(milli.to_i)}
      property :measurement, lambda {|m| "#{m.value}:#{m.units}"}, lambda {|m| value,units = m.split(/:/); Measurement.new(value.to_f, units)}
    end

    sample = WaterSample.new
    sample.subject = "Arsenic Levels"
    sample.time = Time.now
    sample.measurement = Measurement.new(0.05, "ppm")

    key = sample.save
    => "some uuid here"

    last_sample = Sample.find(key)

### Embedded Documents
There is also support for embedded documents.  If you declare a property with a type that includes Zebris::Document, what
you will get is an embedded serialization of the property when you save.  This is different than a relational model where
the two documents are stored separately and related together via keys.

    class Listing
      include Zebris::Document

      key {UUID.generate}

      collection :people, Person

      class Person
        include Zebris::Document

        # No key needed since this is embedded

        property :name, String
        property :age, Integer

        def initialize(name, age)
          @name = name
          @age = age
        end
      end
    end

    l = Listing.new
    l.people << Listing::Person.new("John", 30)
    l.people << Listing::Person.new("Mary", 28)

    key = l.save

    # ... some time later ...
    l2 = Listing.find(key)

    # Our listings are back

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
