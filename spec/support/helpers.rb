require 'payload'
require 'date'

RSpec.shared_context 'test helpers' do
  before(:all) do
    Payload.api_key = ENV['TEST_SECRET_KEY']
    if ENV['TEST_API_URL']
      Payload.api_url = ENV['TEST_API_URL']
    end
  end
end

# Load version-specific helpers
require_relative 'helpers/v1_helpers'
require_relative 'helpers/v2_helpers'
