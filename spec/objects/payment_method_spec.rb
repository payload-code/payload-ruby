require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Payment Method Integration Tests' do
  include_context 'test helpers'

  describe 'Payment Methods' do
    it 'creates a payment with card' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      expect(card_payment.status).to eq('processed')
    end

    it 'creates a payment with bank account' do
      bank_payment = create_bank_payment
      expect(bank_payment.status).to eq('processed')
    end

    it 'filters payments' do
      proc_account = create_processing_account
      rand_description = (0...10).map { ('a'..'z').to_a[rand(26)] }.join

      card_payment = Payload::Payment.create(
        amount: 100.0,
        description: rand_description,
        processing_id: proc_account.id,
        payment_method: {
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
            expiry: '05/35',
            card_code: '123',
          },
          billing_address: { postal_code: '11111' }
        }
      )

      payments = Payload::Payment.filter_by(
        amount: { '>' => 99, '<' => 200 },
        description: rand_description
      ).all

      expect(payments.length).to be >= 1
      expect(payments.map(&:id)).to include(card_payment.id)
    end

    it 'voids a card payment' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      card_payment.update(status: 'voided')
      expect(card_payment.status).to eq('voided')
    end

    it 'voids a bank payment' do
      bank_payment = create_bank_payment
      bank_payment.update(status: 'voided')
      expect(bank_payment.status).to eq('voided')
    end

    it 'refunds a card payment' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      refund = Payload::Refund.create(
        amount: card_payment.amount,
        ledger: [{assoc_transaction_id: card_payment.id}]
      )

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(card_payment.amount)
      expect(refund.status_code).to eq('approved')
    end

    it 'partially refunds a card payment' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      refund = Payload::Refund.create(
        amount: 10,
        ledger: [{assoc_transaction_id: card_payment.id}]
      )

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(10)
      expect(refund.status_code).to eq('approved')
    end

    it 'creates a blind refund for card payment' do
      proc_account = create_processing_account
      refund = Payload::Refund.create(
        amount: 10,
        processing_id: proc_account.id,
        payment_method: {
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
            expiry: '12/25',
            card_code: '123'
          },
          billing_address: { postal_code: '11111' }
        }
      )

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(10)
      expect(refund.status_code).to eq('approved')
    end

    it 'refunds a bank payment' do
      bank_payment = create_bank_payment
      refund = Payload::Refund.create(
        amount: bank_payment.amount,
        ledger: [{assoc_transaction_id: bank_payment.id}]
      )

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(bank_payment.amount)
      expect(refund.status_code).to eq('approved')
    end

    it 'partially refunds a bank payment' do
      bank_payment = create_bank_payment
      refund = Payload::Refund.create(
        amount: 10,
        ledger: [{amount: 10, assoc_transaction_id: bank_payment.id}]
      )

      expect(refund.type).to eq('refund')
      expect(refund.amount).to eq(10)
      expect(refund.status_code).to eq('approved')
    end

    it 'raises error for invalid payment method type' do
      expect {
        Payload::Transaction.create(
          type: 'invalid',
          card_number: '4242 4242 4242 4242',
          expiry: '12/25'
        )
      }.to raise_error(Payload::InvalidAttributes)
    end
  end
end

