require 'payload'
require_relative 'helpers'

RSpec.describe 'Test helpers API versions' do
  include_context 'test helpers'

  describe '#create_processing_account' do
    [1, 2].each do |api_version|
      context "api_version=#{api_version}" do
        let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, api_version) }
        let(:h) { Object.const_get("V#{api_version}Helpers").new(session) }

        it 'returns a processing account' do
          account = h.create_processing_account
          expect(account).to respond_to(:id)
        end
      end
    end
  end
end

