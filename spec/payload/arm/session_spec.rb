require "payload"
require "payload/arm/object"


RSpec.describe Payload::Session do

    describe "#initialize" do
        context "when the user initializes a session with only an API key" do
            let(:instance1) { described_class.new('test_key') }
    
            it "sets the api key and uses default url" do
                expect(instance1.api_key).to eq('test_key')
                expect(instance1.api_url).to eq('https://api.payload.co')
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

                instance = Payload::Session.new('test_key')

                arm_request = instance.query(Payload::Customer)

                expect(arm_request.instance_variable_get(:@cls)).to eq(Payload::Customer)
            end
        end
    end
end
