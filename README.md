# Zebris

Zebris is built to allow you to add persisting and retrieving your objects to and from Redis with a minimum of hassle or re-writing of your code.
When I needed a library to do something similar, I noticed that a lot of the other Redis persistence libraries were very opinionated or tried to
implement the ActiveRecord pattern, which is nice but would have required me to re-write a lot of code to conform to the libraries idioms than I
wanted to do.  My goal was to make it as easy as possible to add a Gem to my project and with as little code as possible make it easy to persist
the object to Redis and retrieve it later.

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
