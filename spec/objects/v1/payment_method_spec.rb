require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Payment Method Integration Tests - V1' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }
  let(:h) { V1Helpers.new(session) }
  let(:proc_account) { h.create_processing_account }

  describe 'Payment Methods' do
    it 'creates a payment with card' do
      card_payment = h.create_card_payment(proc_account.id)
      expect(card_payment.status).to eq('processed')
    end

    it 'creates a payment with bank account' do
      bank_payment = h.create_bank_payment
      expect(bank_payment.status).to eq('processed')
    end

    it 'filters payments' do
      rand_description = (0...10).map { ('a'..'z').to_a[rand(26)] }.join

      amounts = [90.0, 100.0, 110.0]
      card_payments = []
      amounts.each do |amount|
        card_payment = h.create_card_payment(proc_account.id, amount: amount, description: rand_description)
        card_payments << card_payment
      end

      payments = session.Transaction.filter_by(
        type: 'payment',
        amount: '100',
        description: rand_description
      ).all

      expect(payments.length).to be == 1
      expect(payments.map(&:id)).to include(card_payments[1].id)
    end

    it 'voids a card payment' do
      card_payment = h.create_card_payment(proc_account.id)
      card_payment.update(status: 'voided')
      expect(card_payment.status).to eq('voided')
    end

    it 'voids a bank payment' do
      bank_payment = h.create_bank_payment
      bank_payment.update(status: 'voided')
      expect(bank_payment.status).to eq('voided')
    end

    it 'refunds a card payment' do
      card_payment = h.create_card_payment(proc_account.id)
      refund = h.create_refund(card_payment)

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(card_payment.amount)
    end

    it 'partially refunds a card payment' do
      card_payment = h.create_card_payment(proc_account.id)
      amount = (card_payment.amount/2).round(2) # rounded to 2 decimal places
      refund = h.create_refund(card_payment, amount: amount)

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(amount)
    end

    it 'creates a blind refund for card payment' do
      refund = h.create_blind_refund(10, proc_account.id)

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(10)
    end

    it 'refunds a bank payment' do
      bank_payment = h.create_bank_payment
      refund = h.create_refund(bank_payment)

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(bank_payment.amount)
    end

    it 'partially refunds a bank payment' do
      bank_payment = h.create_bank_payment
      amount = (bank_payment.amount/2).round(2) # rounded to 2 decimal places
      refund = h.create_refund(bank_payment, amount: amount)

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(amount)
    end

    it 'raises error for invalid payment method type' do
      expect {
        session.Transaction.create(
          type: 'invalid',
          card_number: '4242 4242 4242 4242',
          expiry: '12/29'
        )
      }.to raise_error(Payload::InvalidAttributes)
    end
  end
end
