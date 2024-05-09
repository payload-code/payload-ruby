require "payload"
require "payload/arm/object"


RSpec.describe Payload::Session do

    describe "#initialize" do
        context "when the user initializes a session with only an API key" do
            let(:instance1) { described_class.new('test_key') }

            it "sets the api key and uses default url" do
                expect(instance1.api_key).to eq('test_key')
                expect(instance1.api_url).to eq('https://api.payload.com')
            end
        end

        context "when the user initializes a session with an API key and a URL" do
            let(:instance2) { described_class.new('test_key', 'https://api.hello.co') }

            it "sets the api key and url" do
                expect(instance2.api_key).to eq('test_key')
                expect(instance2.api_url).to eq('https://api.hello.co')
            end
        end
    end

    describe "#query" do

        context "when the user queries an ARMObject with a session" do
            it "builds the appropriate ARMRequest" do

                $test_id = 'acct_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                arm_request = instance.query(Payload::Customer)

                expect(arm_request.instance_variable_get(:@cls)).to eq(Payload::Customer)
                expect(arm_request.instance_variable_get(:@session)).to eq(instance)

                expect(arm_request).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("GET")
                    expect(http.address).to eq("sandbox.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('session_key')
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
                                    {"id": "' + $test_id + '", "object": "customer", "name": "John Doe", "age": 42}
                                ]
                            }'
                        end
                    end

                    MockResponse.new
                end

                expect(Payload::Customer.class_variable_get(:@@cache).key?(instance.object_id)).to eq(false)

                custs = arm_request.select('name', 'age').all()

                expect(custs).to be_a(Array)
                expect(custs.size).to eq(1)
                expect(custs[0]).to be_a(Payload::Customer)
                expect(custs[0].object).to eq('customer')
                expect(custs[0].session).to eq(instance)

                expect(Payload::Customer.class_variable_get(:@@cache)[instance.object_id][$test_id]['name']).to eq('John Doe')
                expect(Payload::Customer.class_variable_get(:@@cache)[instance.object_id][$test_id]['age']).to eq(42)
            end
        end
    end

    describe "#create" do

        context "when the user creates an ARMObject with a session" do

            it "builds the appropriate ARMRequest" do
                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                cust = Payload::Customer.new({})

                expect_any_instance_of(Payload::ARMRequest).to receive(:create) do |req, objects|
                    expect(req.instance_variable_get(:@session)).to eq(instance)
                    expect(objects).to eq(cust)
                end

                instance.create(cust)
            end
        end
    end

    describe "#update" do

        context "when the user updates an ARMObject with a session" do

            it "builds the appropriate ARMRequest" do
                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                cust = Payload::Customer.new({})

                expect_any_instance_of(Payload::ARMRequest).to receive(:update_all) do |req, objects|
                    expect(req.instance_variable_get(:@session)).to eq(instance)
                    expect(objects).to eq(cust)
                end

                instance.update(cust)
            end
        end
    end

    describe "#delete" do

        context "when the user deletes an ARMObject with a session" do

            it "builds the appropriate ARMRequest" do
                Payload::api_key = 'test_key'
                instance = Payload::Session.new('session_key', 'https://sandbox.payload.com')

                cust = Payload::Customer.new({})

                expect_any_instance_of(Payload::ARMRequest).to receive(:delete_all) do |req, objects|
                    expect(req.instance_variable_get(:@session)).to eq(instance)
                    expect(objects).to eq(cust)
                end

                instance.delete(cust)
            end
        end
    end
end
