require "payload"
require "payload/arm/object"


RSpec.describe Payload::ARMRequest do

    describe "#select" do

        let(:instance) { described_class.new }

        context "when the user selects custom fields" do
            it "merges the given data with the class's polymorphic association" do
                instance.select(' name', 'age  ')
                expect(instance.instance_variable_get(:@filters)).to eq({ "fields" => "name,age" })
                instance.select('count(id)', 'sum(amount)')
                expect(instance.instance_variable_get(:@filters)).to eq({ "fields" => "count(id),sum(amount)" })
            end
        end
    end

    describe "#filter_by" do

        let(:instance) do
            class TestObject < Payload::ARMObject
                @poly = { "type" => "test" }
            end
            Payload::ARMRequest.new(TestObject)
        end
        
        context "when the class does not have a polymorphic association" do
            it "sets the given data as filters" do
                instance.filter_by(name: "John", age: 30)
                expect(instance.instance_variable_get(:@filters)).to eq({name: "John", age: 30, "type" => "test"})
            end
        end
        
        context "when called multiple times" do
            it "merges all the given data into a single hash" do
                instance.filter_by(name: "John", city: "San Francisco")
                instance.filter_by(age: ['<30', '>20'])
                expect(instance.instance_variable_get(:@filters)).to eq({name: "John", age: ['<30', '>20'], city: "San Francisco", "type" => "test"})
            end
        end
    end
end
