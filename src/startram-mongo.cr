require "activesupport/activesupport/core_ext/string"
require "startram/startram/model"
require "mongo"

require "./startram-mongo/*"

module Startram
  module Mongo
    def self.database=(database)
      @@database = database
    end

    def self.database
      @@database.not_nil!
    end

    module Errors
      class DocumentNotFound < Exception
        def initialize(id)
          super "Document(s) not found for class Story with id(s) #{id}."
        end
      end
    end

    module InstanceMethods
      macro included
        field :_id, String, BSON::ObjectId
      end

      def id
        _id
      end

      def save
        attributes["_id"] ||= BSON::ObjectId.new.to_s[0..-2]
        collection.insert(attributes)
        last_error = collection.last_error
        puts "last_error: #{last_error}"
      end

      private def collection
        self.class.collection
      end
    end

    module ClassMethods
      def database=(database)
        @@database = database
      end

      def database
        @@database ||= Startram::Mongo.database
      end

      def collection_name
        @@collection_name ||= to_s.tableize
      end

      def collection
        database[collection_name]
      end

      def find(id)
        if doc = collection.find_one({"_id" => BSON::ObjectId.new(id)})
          new doc_to_attributes(doc)
        else
          raise Errors::DocumentNotFound.new(id)
        end
      end

      def attributes_to_doc(attributes)
        @@fields.values.inject({} of String => BSON::Field) do |doc, field_data|
          name = field_data.name
          if attributes.has_key?(name)
            value coerce_attribute doc[name]
            doc[name] = value
          end
        end
      end

      private def doc_to_attributes(doc)
        @@fields.values.inject(Startram::Model::Attributes.new) do |attributes, field_data|
          name = field_data.name
          if doc.has_key?(name)
            value = coerce_bson doc[name], field_data
            attributes[name] = value
          end
          attributes
        end
      end

      # BSON document value types:
      # String | Int32 | Int64 | Float64 | Time | Bool | Regex | BSON | BSON::Code |
      # BSON::ObjectId | BSON::Timestamp | BSON::MinKey | BSON::MaxKey | BSON::Symbol
      private def coerce_bson(value)
        case value
        when String
          value as String
        when Int32
          value as Int32
        when Int64
          value as Int64
        when Time
          value as Time
        when Bool
          value as Bool
        end
      end

      private def coerce_attribute(value, field_data)
        if field_data.database_type == BSON::ObjectId
          BSON::ObjectId.new(value)
        else
          value
        end
      end
    end
  end
end
