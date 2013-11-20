require "zebris/version"
require "zebris/types"
require "zebris/document"
require 'json'

module Zebris
  def self.redis=(connection)
    @@redis = connection
  end

  def self.redis
    @@redis
  end
end
