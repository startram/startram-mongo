require "spec"
require "../src/startram-mongo"

client = Mongo::Client.new "mongodb://localhost"
database = client["startram_mongo_test"]

Startram::Mongo.database = database

Spec.before_each do
  database.drop
end
