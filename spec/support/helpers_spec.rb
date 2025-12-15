require 'payload'
require_relative 'helpers'

RSpec.describe 'Test helpers API versions' do
  include_context 'test helpers'

  describe '#create_processing_account' do
    it 'returns a processing account for v1 by default' do
      account = create_processing_account
      expect(account).to respond_to(:id)
    end

    it 'returns an account for v2 when api_version: 2' do
      account = create_processing_account(api_version: 2)
      expect(account).to respond_to(:id)
    end
  end

  describe '#create_bank_payment' do
    [1, 2].each do |api_version|
      it "returns a processed bank payment for API v#{api_version}" do
        payment = create_bank_payment(api_version: api_version)
        status = api_version == 1 ? payment.status : payment.status['value']
        expect(status).to eq('processed')
      end
    end
  end
end

