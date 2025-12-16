require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Payment Link Integration Tests - V1' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }
  let(:h) { V1Helpers.new(session) }

  describe 'Payment Link' do

    it 'creates a one-time payment link' do
      proc_account = h.create_processing_account
      payment_link = h.create_payment_link_one_time(proc_account)

      expect(payment_link.processing_id).to eq(proc_account.id)
      expect(payment_link.type).to eq('one_time')
    end

    it 'creates a reusable payment link' do
      proc_account = h.create_processing_account
      payment_link = h.create_payment_link_reusable(proc_account)

      expect(payment_link.processing_id).to eq(proc_account.id)
      expect(payment_link.type).to eq('reusable')
    end

    it 'deletes a reusable payment link' do
      proc_account = h.create_processing_account
      payment_link = h.create_payment_link_reusable(proc_account)
      payment_link.delete

      expect {
        session.PaymentLink.get(payment_link.id)
      }.to raise_error(Payload::NotFound)
    end

    it 'deletes a one-time payment link' do
      proc_account = h.create_processing_account
      payment_link = h.create_payment_link_one_time(proc_account)
      payment_link.delete

      expect {
        session.PaymentLink.get(payment_link.id)
      }.to raise_error(Payload::NotFound)
    end
  end
end

