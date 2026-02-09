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

    describe "#attr" do
        it "returns an AttrRoot so pl.attr.name returns an Attr (not shadowed by Class#name)" do
            instance = described_class.new("test_key", "https://api.hello.co")
            root = instance.attr

            expect(root).to be_a(Payload::AttrRoot)
            expect(root.id).to be_a(Payload::Attr)
            expect(root.id.to_s).to eq("id")

            expect(root.created_at(:year)).to be_a(Payload::Attr)
            expect(root.created_at(:year).to_s).to eq("year(created_at)")

            expect(root.created_at.year.to_s).to eq("created_at[year]")
        end
    end

    describe "query chaining with session" do
        it "passes session through query -> select -> order_by -> limit chain" do
            instance = described_class.new("session_key", "https://api.test.com", "v2")
            req = instance.query(Payload::Invoice).select("id", "amount").order_by("created_at").limit(5)

            expect(req).to be_a(Payload::ARMRequest)
            expect(req.instance_variable_get(:@session)).to eq(instance)
            expect(req.instance_variable_get(:@filters)["fields"]).to eq("id,amount")
            expect(req.instance_variable_get(:@order_by)).to include("created_at")
            expect(req.instance_variable_get(:@limit)).to eq(5)
        end

        it "filter_by with session.attr uses AttrRoot from same session" do
            instance = described_class.new("test_key", "https://api.test.com", "v2")
            filter_expr = instance.attr.status == "processed"
            req = instance.query(Payload::Transaction).filter_by(filter_expr)

            expect(req.instance_variable_get(:@session)).to eq(instance)
            expect(req.instance_variable_get(:@filter_objects)).to include(be_a(Payload::ARMEqual))
            params = req.request_params
            expect(params["status"]).to eq("processed")
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
