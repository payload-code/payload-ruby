require "payload"
require "payload/arm/object"
require 'base64'


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

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?fields=name%2Cage")

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
                                    {"id": "' + $test_id + '", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                custs = instance.select('name', 'age').all()

                expect(custs.size).to eq(1)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))
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
                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
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
                
                custs = instance.filter_by(name: "John", age: 30).all()

                expect(custs.size).to eq(1)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))
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

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"type\":\"bill\",\"processing_id\":\"acct_3bz0zU99AX06SJwfMmfn0\",\"due_date\":\"2020-01-01\",\"items\":[{\"entry_type\":\"charge\",\"type\":\"item1\",\"amount\":29.99}],\"customer_id\":\"acct_3bW9JMoGYQul5fCIa9f8q\"}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                cust = instance.create(
                    type: 'bill',
                    processing_id: 'acct_3bz0zU99AX06SJwfMmfn0',
                    due_date: '2020-01-01',
                    items: [
                        Payload::ChargeItem.new(
                            type: 'item1',
                            amount: 29.99
                        )
                    ],
                    customer_id: 'acct_3bW9JMoGYQul5fCIa9f8q'
                )
                expect(cust.id).to eq($test_id)
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user creates multiple objects" do
            it "executes the appropriate request and returns the appropriate objects" do

                $test_id_a = 'acct_' + rand(9000000...9999999).to_s
                $test_id_b = 'acct_' + rand(9000000...9999999).to_s
                $test_id_c = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)
            
                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
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
                                {"id": "' + $test_id_a + '", "object": "customer"},
                                {"id": "' + $test_id_b + '", "object": "customer"},
                                {"id": "' + $test_id_c + '", "object": "customer"}
                            ]
                            }'
                        end
                    end
            
                    MockResponse.new
                end
            
                customers = instance.create([{ name: "John", age: 30 }, { name: "Alice", age: 25 }, { name: "Bob", age: 35 }])
                expect(customers.size).to eq(3)
            
                expect(customers[0].id).to eq($test_id_a)
                expect(customers[0].object).to eq("customer")
                expect(customers[0].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[1].id).to eq($test_id_b)
                expect(customers[1].object).to eq("customer")
                expect(customers[1].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[2].id).to eq($test_id_c)
                expect(customers[2].object).to eq("customer")
                expect(customers[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
        
        context "when the user creates multiple objects using ARMObjects" do
            it "executes the appropriate request and returns the appropriate objects" do

                $test_id_a = 'acct_' + rand(9000000...9999999).to_s
                $test_id_b = 'acct_' + rand(9000000...9999999).to_s
                $test_id_c = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)
            
                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
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
                                    {"id": "' + $test_id_a + '", "object": "customer"},
                                    {"id": "' + $test_id_b + '", "object": "customer"},
                                    {"id": "' + $test_id_c + '", "object": "customer"}
                                ]
                            }'
                        end
                    end
            
                    MockResponse.new
                end
            
                customers = instance.create([{ name: "John", age: 30 }, { name: "Alice", age: 25 }, { name: "Bob", age: 35 }])
                expect(customers.size).to eq(3)
            
                expect(customers[0].id).to eq($test_id_a)
                expect(customers[0].object).to eq("customer")
                expect(customers[0].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[1].id).to eq($test_id_b)
                expect(customers[1].object).to eq("customer")
                expect(customers[1].session).to eq(instance.instance_variable_get(:@session))
            
                expect(customers[2].id).to eq($test_id_c)
                expect(customers[2].object).to eq("customer")
                expect(customers[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "#get" do

        let(:instance) { described_class.new }

        context "when the user gets an object" do

            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers/" + $test_id + "?")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                cust = instance.get($test_id)
                expect(cust.id).to eq($test_id)
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "#update" do

        let(:instance) { described_class.new }

        context "when the user updates an object" do

            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers/" + $test_id + "?")
                    expect(request.body).to eq("{\"name\":\"John\",\"age\":30}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end

                cust = Payload::Customer.new(id: $test_id).update(name: "John", age: 30)
                expect(cust.id).to eq($test_id)
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user updates an object that is part of a session" do

            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                cust = Payload::Customer.new({id: $test_id})
                cust.set_session(instance)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("sandbox.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('session_key')
                    expect(request.path).to eq("/customers/" + $test_id + "?")
                    expect(request.body).to eq("{\"name\":\"John\",\"age\":30}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end

                cust.update(name: "John", age: 30)
            end
        end

        context "when the user updates multiple objects" do

            it "executes the appropriate request and returns the appropriate objects" do

                $test_id_a = 'acct_' + rand(9000000...9999999).to_s
                $test_id_b = 'acct_' + rand(9000000...9999999).to_s
                $test_id_c = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"object\":\"list\",\"values\":[{\"name\":\"John\",\"age\":30,\"id\":\"" + $test_id_a + "\"},{\"name\":\"Alice\",\"age\":25,\"id\":\"" + $test_id_b + "\"},{\"name\":\"Bob\",\"age\":35,\"id\":\"" + $test_id_c + "\"}]}")

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
                                    {"id": "' + $test_id_a + '", "object": "customer"},
                                    {"id": "' + $test_id_b + '", "object": "customer"},
                                    {"id": "' + $test_id_c + '", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                custs = Payload::update([
                    [Payload::Customer.new(id: $test_id_a), { name: "John", age: 30 }],
                    [Payload::Customer.new(id: $test_id_b), { name: "Alice", age: 25 }],
                    [Payload::Customer.new(id: $test_id_c), { name: "Bob", age: 35 }]
                ])

                expect(custs.size).to eq(3)

                expect(custs[0].id).to eq($test_id_a)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[1].id).to eq($test_id_b)
                expect(custs[1].object).to eq("customer")
                expect(custs[1].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[2].id).to eq($test_id_c)
                expect(custs[2].object).to eq("customer")
                expect(custs[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user updates multiple objects via query" do

            it "executes the appropriate request and returns the appropriate objects" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("PUT")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?name=John+Smith&mode=query")
                    expect(request.body).to eq("{\"name\":\"John\",\"age\":30}")

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
                                    {"id": "' + $test_id + '", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                custs = Payload::Customer.
                    filter_by(name: 'John Smith').
                    update(name: "John", age: 30)

                expect(custs.size).to eq(1)

                expect(custs[0].id).to eq($test_id)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "#delete" do

        let(:instance) { described_class.new }

        context "when the user deletes an object" do

            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("DELETE")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers/" + $test_id + "?")
                    expect(request.body).to eq(nil)

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end

                cust = Payload::Customer.new(id: $test_id).delete()
                expect(cust.id).to eq($test_id)
                expect(cust.object).to eq("customer")
                expect(cust.session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user updates an object that is part of a session" do

            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                cust = Payload::Customer.new({id: $test_id})
                cust.set_session(instance)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("DELETE")
                    expect(http.address).to eq("sandbox.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('session_key')
                    expect(request.path).to eq("/customers/" + $test_id + "?")
                    expect(request.body).to eq(nil)

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "customer"
                            }'
                        end
                    end

                    MockResponse.new
                end

                cust.delete()
            end
        end

        context "when the user deletes multiple objects" do

            it "executes the appropriate request and returns the appropriate objects" do

                $test_id_a = 'acct_' + rand(9000000...9999999).to_s
                $test_id_b = 'acct_' + rand(9000000...9999999).to_s
                $test_id_c = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("DELETE")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?")
                    expect(request.body).to eq("{\"object\":\"list\",\"values\":[{\"id\":\"" + $test_id_a + "\"},{\"id\":\"" + $test_id_b + "\"},{\"id\":\"" + $test_id_c + "\"}]}")

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
                                    {"id": "' + $test_id_a + '", "object": "customer"},
                                    {"id": "' + $test_id_b + '", "object": "customer"},
                                    {"id": "' + $test_id_c + '", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                custs = Payload::delete([
                    Payload::Customer.new(id: $test_id_a),
                    Payload::Customer.new(id: $test_id_b),
                    Payload::Customer.new(id: $test_id_c)
                ])

                expect(custs.size).to eq(3)

                expect(custs[0].id).to eq($test_id_a)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[1].id).to eq($test_id_b)
                expect(custs[1].object).to eq("customer")
                expect(custs[1].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[2].id).to eq($test_id_c)
                expect(custs[2].object).to eq("customer")
                expect(custs[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end

        context "when the user deletes multiple objects via query" do

            it "executes the appropriate request and returns the appropriate objects" do

                $test_id_a = 'acct_' + rand(9000000...9999999).to_s
                $test_id_b = 'acct_' + rand(9000000...9999999).to_s
                $test_id_c = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Customer)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("DELETE")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/customers?name=John+Smith&mode=query")
                    expect(request.body).to eq(nil)

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
                                    {"id": "' + $test_id_a + '", "object": "customer"},
                                    {"id": "' + $test_id_b + '", "object": "customer"},
                                    {"id": "' + $test_id_c + '", "object": "customer"}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                custs = Payload::Customer.
                    filter_by(name: 'John Smith').
                    delete()

                expect(custs.size).to eq(3)

                expect(custs[0].id).to eq($test_id_a)
                expect(custs[0].object).to eq("customer")
                expect(custs[0].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[1].id).to eq($test_id_b)
                expect(custs[1].object).to eq("customer")
                expect(custs[1].session).to eq(instance.instance_variable_get(:@session))

                expect(custs[2].id).to eq($test_id_c)
                expect(custs[2].object).to eq("customer")
                expect(custs[2].session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end

    describe "API version header functionality" do

        # Mock object for testing
        class MockObject < Payload::ARMObject
            @spec = { 'object' => 'mock_object', 'endpoint' => '/mock' }
        end

        context "when session.api_version is set" do
            it "includes X-API-Version header in GET requests" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', '2.1')
                instance = Payload::ARMRequest.new(MockObject, session)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(request['X-API-Version']).to eq('2.1')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.get($test_id)
            end
        end

        context "when session.api_version is nil" do
            it "does not include X-API-Version header" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', nil)
                instance = Payload::ARMRequest.new(MockObject, session)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(request['X-API-Version']).to be_nil

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.get($test_id)
            end
        end

        context "when no session is provided" do
            it "uses global Payload.api_version" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                # Set global api_version
                original_version = Payload.api_version
                Payload.api_version = '2.2'

                # Create request without session (will use global Payload module)
                instance = Payload::ARMRequest.new(MockObject, nil)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(request['X-API-Version']).to eq('2.2')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.get($test_id)

                # Restore original version
                Payload.api_version = original_version
            end
        end

        context "when making POST requests" do
            it "includes X-API-Version header" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', '2.3')
                instance = Payload::ARMRequest.new(MockObject, session)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(request['X-API-Version']).to eq('2.3')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.create({ field: 'value' })
            end
        end

        context "when making PUT requests" do
            it "includes X-API-Version header" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', '2.4')
                instance = Payload::ARMRequest.new(MockObject, session)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("PUT")
                    expect(request['X-API-Version']).to eq('2.4')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.update(field: 'new_value')
            end
        end

        context "when making DELETE requests" do
            it "includes X-API-Version header" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', '2.5')

                # Create mock object to delete
                mock_obj = MockObject.new({ id: $test_id })
                mock_obj.set_session(session)

                expect_any_instance_of(Payload::ARMRequest).to receive(:_execute_request) do |inst, http, request|
                    expect(request.method).to eq("DELETE")
                    expect(request['X-API-Version']).to eq('2.5')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                mock_obj.delete
            end
        end

        context "when custom headers are provided" do
            it "merges X-API-Version header with existing headers" do
                $test_id = 'mock_' + rand(9000000...9999999).to_s

                session = Payload::Session.new('test_key', 'https://api.test.com', '2.6')
                instance = Payload::ARMRequest.new(MockObject, session)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    # Verify both Content-Type and X-API-Version headers are present
                    expect(request['Content-Type']).to eq('application/json')
                    expect(request['X-API-Version']).to eq('2.6')

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "object": "mock_object",
                                "id": "' + $test_id + '"
                            }'
                        end
                    end

                    MockResponse.new
                end

                instance.create({ field: 'value' })
            end
        end
    end
end
