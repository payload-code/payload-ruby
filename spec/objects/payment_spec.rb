require "payload"
require "payload/arm/object"
require 'base64'


RSpec.describe Payload::ARMRequest do

    describe "#create" do

        let(:instance) { described_class.new }

        context "when a payment is created for an invoice" do
            it "executes the appropriate request and returns the appropriate object" do

                $test_id = 'txn_' + rand(9000000...9999999).to_s

                Payload::api_key = 'test_key'
                instance.instance_variable_set(:@cls, Payload::Payment)

                expect(instance).to receive(:_execute_request) do |http, request|
                    expect(request.method).to eq("POST")
                    expect(http.address).to eq("api.payload.com")
                    expect(Base64.decode64(request['authorization'].split(' ')[1]).split(':')[0]).to eq('test_key')
                    expect(request.path).to eq("/transactions?")
                    expect(request.body).to eq("{\"amount\":129.0,\"customer_id\":\"acct_3bW9JMoGYQul5fCIa9f8q\",\"allocations\":[{\"entry_type\":\"payment\",\"invoice_id\":\"inv_3eNP6uf94xHTXr0rMyvZJ\"}],\"type\":\"payment\"}")

                    class MockResponse
                        def initialize
                        end

                        def code
                            '200'
                        end

                        def body
                            '{
                                "id": "' + $test_id + '",
                                "object": "transaction"
                            }'
                        end
                    end

                    MockResponse.new
                end
                
                payment = instance.create(
                  amount: 129.0,
                    customer_id: 'acct_3bW9JMoGYQul5fCIa9f8q',
                    allocations: [
                        Payload::PaymentItem.new(
                            invoice_id: 'inv_3eNP6uf94xHTXr0rMyvZJ'
                        )
                    ],
                )

                expect(payment.id).to eq($test_id)
                expect(payment.object).to eq("transaction")
                expect(payment.session).to eq(instance.instance_variable_get(:@session))
            end
        end
    end
end
