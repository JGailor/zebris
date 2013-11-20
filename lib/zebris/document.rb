module Zebris
  module Document
    def self.included(klass)
      klass.extend(ClassMethods)
      Zebris::Types.constants.each do |const|
        clazz = Zebris::Types.const_get(const)
        klass.const_set const, clazz
      end
    end

    def save
      self.class.scrub
      data = self.class.serialize(self)

      Zebris.redis.set self.key, data.to_json
    end

    def key
      @key ||= self.class.keygen.call
    end

    module ClassMethods
      def const_missing(const)
        const
      end

      def find(key)
        stored = Zebris.redis.get key

        if stored
          data = JSON.parse(stored)
          deserialize(data)
        else
          nil
        end
      end

      def serialize(object)
        attributes = {"key" => object.key}

        properties.each do |property, conversion|
          if val = object.send(property.to_sym)
            if conversion.kind_of?(Zebris::Types::GenericConverter)
              attributes[property.to_s] = conversion.serializer.call(val)
            else
              attributes[property.to_s] = conversion.serialize(val)
            end
          end
        end

        collections.each do |property, klass|
          attributes[property] ||= []
          object.send(:instance_variable_get, :"@#{property}").each do |record|
            attributes[property] << record.serialize
          end
        end

        attributes
      end

      def scrub
        unless @scrubbed
          self.properties.each do |property, type|
            unless type.kind_of?(Zebris::Types::GenericConverter)
              if type.kind_of?(Symbol)
                type = self.properties[property] = self.const_get(self.properties[property])
              end

              unless type.ancestors.include?(Zebris::Document) || self.properties[property].to_s.start_with?(Zebris::Types.to_s)
                raise "#{type} does not implement the Zebris::Document interface"
              end
            end
          end

          self.collections.each do |property, type|
            if self.collections[property].kind_of?(Symbol)
              self.collections[property] = self.const_get(self.collections[property])
            end
          end

          @scrubbed = true
        end
      end

      def deserialize(data)
        scrub

        self.new.tap do |instance|
          data.each do |property, value|
            property = property.to_sym
            if self.properties[property]
              if self.properties[property].kind_of?(Zebris::Types::GenericConverter)
                instance.send(:"#{property}=", self.properties[property].deserializer.call(value))
              else
                instance.send(:"#{property}=", self.properties[property].deserialize(value))
              end
            elsif self.collections[property] && value.instance_of?(Array)
              value.each do |row|
                instance.send(:"instance_variable_get", :"@#{property}") << self.collections[property].deserialize(row)
              end
            end
          end
        end
      end

      def key(&block)
        self.class.instance_variable_set(:@keygen, block)
      end

      def keygen
        self.class.instance_variable_get(:@keygen)
      end

      def properties
        @properties ||= {}
      end

      def property(name, type_or_serializer, deserializer = nil)
        if type_or_serializer.kind_of?(Proc)
          raise "When providing a deserializer you need to provide a deserializer" if deserializer.nil?
          properties[name] = Zebris::Types::GenericConverter.new(type_or_serializer, deserializer)
        else
          properties[name] = type_or_serializer
        end
        self.send(:attr_accessor, name)
      end

      def collections
        @collections ||= {}
      end

      def collection(name, klass)
        collections[name] = klass
        self.send(:attr_accessor, name)
      end
    end
  end
end