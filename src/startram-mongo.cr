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
      def save
        collection.insert(attributes)
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

      private def doc_to_attributes(doc)
        @@fields.values.inject(Startram::Model::Attributes.new) do |attributes, field_data|
          name = field_data.name
          if doc.has_key?(name)
            value = coerce_bson doc[name]?
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
    end
  end
end
