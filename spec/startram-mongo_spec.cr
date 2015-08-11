require "./spec_helper"

class TestModel
  include Startram::Model
  include Startram::Mongo::InstanceMethods
  extend Startram::Mongo::ClassMethods

  field :name, String
  field :age, Int32
  field :poked_at, Time, default: -> { Time.at(108) }
  field :happy, Bool, default: true
end

describe Startram::Mongo do
  describe ".collection_name" do
    it "does is the tableized class name" do
      TestModel.collection_name.should eq "test_models"
    end
  end

  describe ".collection" do
    it "is the database collection" do
      collection = TestModel.collection

      collection.class.should eq Mongo::Collection
      collection.name.should eq TestModel.collection_name
    end
  end

  describe ".find" do
    it "instantiates a model form the database" do
      id = BSON::ObjectId.new

      TestModel.collection.insert({
        "_id" => id
        "name" => "James Bond"
        "age" => 37
        "poked_at" => Time.at(99)
        "happy" => false
      })

      model = TestModel.find(id.to_s)

      model.attributes.should eq({
        "name" => "James Bond"
        "age" => 37
        "poked_at" => Time.at(99)
        "happy" => false
      })
    end

    it "raises DocumentNotFound error unless found" do
      expect_raises Startram::Mongo::Errors::DocumentNotFound, "Document(s) not found for class Story with id(s) asdf." do
        TestModel.find("asdf")
      end
    end
  end

  describe "#save" do
    it "persists the model to the database" do
      model = TestModel.new({"name" => "Awesome", "age" => 23})

      model.save

      doc = TestModel.collection.find_one({"name" => "Awesome"})

      doc.should_not be_nil

      if doc
        doc["name"].should eq "Awesome"
        doc["age"]?.should eq 23
        doc["poked_at"]?.should eq Time.at(108)
        doc["happy"]?.should eq true
      end
    end
  end
end
