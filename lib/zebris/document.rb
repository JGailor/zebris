module Zebris
  module Document
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def save
      raise "#{self.class} does not define a key generator" unless self.class.keygen.kind_of?(Proc)

      data = self.class.serialize(self)

      result = Zebris.redis.set self.key, data.to_json

      raise "Could not save #{self.class}" unless result == "OK"

      self.key
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

      def serialize(object, embed = false)
        scrub
        attributes = (embed ? {} : {"key" => object.key})
        attributes.merge!(serialize_properties(object))
        attributes.merge!(serialize_collections(object))
      end

      def scrub
        unless @scrubbed
          self.properties.each do |property, type|
            unless type.kind_of?(Zebris::Types::GenericConverter)
              resolved_type = case type
              when Symbol
                if zebris_type?(type)
                  Zebris::Types.const_get(type)
                else
                  klass = lookup_class(type)
                  zebris_document?(klass) ? klass : Zebris::Types::BasicObject
                end
              else
                zebris_document?(type) || zebris_type?(type) ? type : Zebris::Types::BasicObject
              end

              self.properties[property] = resolved_type
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
              instance.send(:"instance_variable_set", :"@#{property}", value.map {|row| self.collections[property].deserialize(row)})
            end
          end
        end
      end

      def key(&block)
        @keygen = block
      end

      def keygen
        @keygen
      end

      def properties
        @properties ||= {}
      end

      def property(name, type_or_serializer, deserializer = nil)
        properties[name] = resolve_type(type_or_serializer, deserializer)

        self.send(:attr_accessor, name)
      end

      def collections
        @collections ||= {}
      end

      def collection(name, klass)
        collections[name] = klass
        self.send(:attr_writer, name)
        self.send(:define_method, :"#{name}") {
          self.send(:instance_variable_get, :"@#{name}") || self.send(:instance_variable_set, :"@#{name}", [])
        }
      end

      private

      def resolve_type(type_or_serializer, deserializer)
        if type_or_serializer.kind_of?(Proc)
          raise "When providing a deserializer you need to provide a deserializer" if deserializer.nil?
          Zebris::Types::GenericConverter.new(type_or_serializer, deserializer)
        else
          type = type_or_serializer.to_s.intern

          if zebris_type?(type)
            Zebris::Types.const_get(type)
          elsif zebris_document?(type_or_serializer)
            type_or_serializer
          else
            type
          end
        end
      end

      def zebris_type?(type)
        type.to_s.start_with?("Zebris::Types") || Zebris::Types.constants.include?(type)
      end

      def zebris_document?(klass)
        klass.respond_to?(:ancestors) ? klass.ancestors.include?(Zebris::Document) : false
      end

      def lookup_class(type)
        if self.constants.include?(type)
          self.const_get(type)
        elsif Module.constants.include?(type)
          Module.const_get(type)
        else
          raise "Could not find class #{type}"
        end
      end

      def serialize_properties(target)
        Hash.new.tap do |attributes|
          properties.each do |property, conversion|
            if val = target.send(property.to_sym)
              if conversion.kind_of?(Zebris::Types::GenericConverter)
                attributes[property.to_s] = conversion.serializer.call(val)
              else
                if conversion.ancestors.include?(Zebris::Document)
                  attributes[property.to_s] = conversion.serialize(val, true)
                else
                  attributes[property.to_s] = conversion.serialize(val)
                end
              end
            end
          end
        end
      end

      def serialize_collections(target)
        Hash.new() {|hash, key| hash[key] = []}.tap do |attributes|
          collections.each do |property, klass|
            raise "#{klass} does not implement the Zebris::Document interface" unless klass.ancestors.include?(Zebris::Document)

            target.send(:instance_variable_get, :"@#{property}").each do |record|
              attributes[property] << klass.serialize(record, true)
            end
          end
        end
      end
    end
  end
end