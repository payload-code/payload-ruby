require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Access Token Integration Tests' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }

  describe 'Access Token' do
    it 'creates a client token' do
      client_token = session.ClientToken.create
      expect(client_token.status).to eq('active')
      expect(client_token.type).to eq('client')
      expect(client_token.environ).to eq('test')
    end
  end
end

