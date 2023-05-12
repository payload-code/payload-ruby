require "payload"
require "payload/arm/object"


RSpec.describe Payload::ARMRequest do

    describe "#select" do

        let(:instance) { described_class.new }

        context "when the user selects custom fields" do
            it "selects the requested fields" do
                instance.select(' name', 'age  ')
                expect(instance.instance_variable_get(:@filters)).to eq({ "fields" => "name,age" })
                instance.select('count(id)', 'sum(amount)')
                expect(instance.instance_variable_get(:@filters)).to eq({ "fields" => "count(id),sum(amount)" })
            end

            it "builds the appropriate select request" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?fields=name%2Cage")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                instance.select('name', 'age').all()
            end
        end
    end

    describe "#filter_by" do

        let(:instance) { described_class.new }
        
        context "when the user filters fields" do
            it "sets the given data as filters" do
                class TestObject < Payload::ARMObject
                    @poly = { "type" => "test" }
                end
                instance.instance_variable_set(:@cls, TestObject)

                instance.filter_by(name: "John", age: 30)
                expect(instance.instance_variable_get(:@filters)).to eq({name: "John", age: 30, "type" => "test"})
            end

            it "builds the appropriate filter_by request" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?name=John&age=30")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "list",
                                "values": [
                                    {
                                        "object": "customer"
                                    }
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                instance.filter_by(name: "John", age: 30).all()
            end
        end
        
        context "when called multiple times" do
            it "merges all the given data into a single hash" do
                class TestObject < Payload::ARMObject
                    @poly = { "type" => "test" }
                end
                instance.instance_variable_set(:@cls, TestObject)
                
                instance.filter_by(name: "John", city: "San Francisco")
                instance.filter_by(age: ['<30', '>20'])
                expect(instance.instance_variable_get(:@filters)).to eq({name: "John", age: ['<30', '>20'], city: "San Francisco", "type" => "test"})
            end
        end
    end

    describe "#create" do

        let(:instance) { described_class.new }

        context "when the user creates an object" do
            it "executes the appropriate request and returns the appropriate object" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"name\":\"John\",\"age\":30}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "acct_123",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                cust = instance.create(name: "John", age: 30)
                expect(cust.id).to eq("acct_123")
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user creates multiple objects" do
            it "executes the appropriate request and returns the appropriate objects" do
                instance.instance_variable_set(:@cls, Payload::Customer)
            
                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"object\":\"list\",\"values\":[{\"name\":\"John\",\"age\":30},{\"name\":\"Alice\",\"age\":25},{\"name\":\"Bob\",\"age\":35}]}")
            
                    class MockResponse
                        def initialize
                        end
                
                        def code
                            '200'
                        end
                
                        def body
                            '{
                            "object": "list",
                            "values": [
                                {"id": "acct_123", "object": "customer"},
                                {"id": "acct_456", "object": "customer"},
                                {"id": "acct_789", "object": "customer"}
                            ]
                            }'
                        end
                    end
            
                    MockResponse.new
                end
            
                customers = instance.create([{ name: "John", age: 30 }, { name: "Alice", age: 25 }, { name: "Bob", age: 35 }])
                expect(customers.size).to eq(3)
            
                expect(customers[0].id).to eq("acct_123")
                expect(customers[0].object).to eq("customer")
                expect(customers[0].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[1].id).to eq("acct_456")
                expect(customers[1].object).to eq("customer")
                expect(customers[1].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[2].id).to eq("acct_789")
                expect(customers[2].object).to eq("customer")
                expect(customers[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
        
        context "when the user creates multiple objects using ARMObjects" do
            it "executes the appropriate request and returns the appropriate objects" do
                instance.instance_variable_set(:@cls, Payload::Customer)
            
                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"object\":\"list\",\"values\":[{\"name\":\"John\",\"age\":30},{\"name\":\"Alice\",\"age\":25},{\"name\":\"Bob\",\"age\":35}]}")
            
                    class MockResponse
                        def initialize
                        end
                
                        def code
                            '200'
                        end
                
                        def body
                            '{
                                "object": "list",
                                "values": [
                                    {"id": "acct_123", "object": "customer"},
                                    {"id": "acct_456", "object": "customer"},
                                    {"id": "acct_789", "object": "customer"}
                                ]
                            }'
                        end
                    end
            
                    MockResponse.new
                end
            
                customers = instance.create([{ name: "John", age: 30 }, { name: "Alice", age: 25 }, { name: "Bob", age: 35 }])
                expect(customers.size).to eq(3)
            
                expect(customers[0].id).to eq("acct_123")
                expect(customers[0].object).to eq("customer")
                expect(customers[0].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[1].id).to eq("acct_456")
                expect(customers[1].object).to eq("customer")
                expect(customers[1].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[2].id).to eq("acct_789")
                expect(customers[2].object).to eq("customer")
                expect(customers[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "#get" do

        let(:instance) { described_class.new }

        context "when the user gets an object" do

            it "executes the appropriate request and returns the appropriate object" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers/acc_1234?")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "acct_123",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                cust = instance.get('acc_1234')
                expect(cust.id).to eq("acct_123")
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "#update" do

        let(:instance) { described_class.new }

        context "when the user updates an object" do

            it "executes the appropriate request and returns the appropriate object" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers/acct_123?")
                    expect(request.body).to eq("{\"name\":\"John\",\"age\":30}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "acct_123",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end

                cust = Payload::Customer.new(id: 'acct_123').update(name: "John", age: 30)
                expect(cust.id).to eq("acct_123")
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user updates multiple objects" do

            it "executes the appropriate request and returns the appropriate objects" do
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("api.payload.co")
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"object\":\"list\",\"values\":[{\"name\":\"John\",\"age\":30,\"id\":\"acct_123\"},{\"name\":\"Alice\",\"age\":25,\"id\":\"acct_456\"},{\"name\":\"Bob\",\"age\":35,\"id\":\"acct_789\"}]}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "list",
                                "values": [
                                    {"id": "acct_123", "object": "customer"},
                                    {"id": "acct_456", "object": "customer"},
                                    {"id": "acct_789", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                custs = Payload::update([
                    [Payload::Customer.new(id: 'acct_123'), { name: "John", age: 30 }],
                    [Payload::Customer.new(id: 'acct_456'), { name: "Alice", age: 25 }],
                    [Payload::Customer.new(id: 'acct_789'), { name: "Bob", age: 35 }]
                ])

                expect(custs.size).to eq(3)

                expect(custs[0].id).to eq("acct_123")
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[1].id).to eq("acct_456")
                expect(custs[1].object).to eq("customer")
                expect(custs[1].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[2].id).to eq("acct_789")
                expect(custs[2].object).to eq("customer")
                expect(custs[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end
end

# TODO - test delete objects
# TODO - test update objects via query
# TODO - test delete objects via query