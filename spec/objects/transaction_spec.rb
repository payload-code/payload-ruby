require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Transaction Integration Tests' do
  include_context 'test helpers'

  describe 'Transactions' do
    it 'has empty transaction ledger' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      transaction = Payload::Transaction.select('*', 'ledger').get(card_payment.id)
      expect(transaction.ledger).to eq([])
    end

    it 'tests unified payout batching' do
      proc_account = create_processing_account
      Payload::Refund.create(
        amount: 10,
        processing_id: proc_account.id,
        payment_method: {
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
            expiry: '12/25',
            card_code: '123'
          },
          billing_address: {
            postal_code: '11111'
          }
        }
      )

      transactions = Payload::Transaction.select('*', 'ledger')
        .filter_by(type: 'refund', processing_id: proc_account.id)
        .all

      expect(transactions.length).to eq(1)
      expect(transactions[0].processing_id).to eq(proc_account.id)
    end

    it 'gets transactions' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      payments = Payload::Transaction.filter_by(status: 'processed', type: 'payment').all
      expect(payments.length).to be > 0
    end

    it 'checks risk flag' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      expect(card_payment.risk_flag).to eq('allowed')
    end

    it 'updates processed transaction' do
      proc_account = create_processing_account
      card_payment = create_card_payment(proc_account)
      card_payment.update(status: 'voided')
      expect(card_payment.status).to eq('voided')
    end

    it 'raises error for transaction not found' do
      expect {
        Payload::Transaction.get('invalid')
      }.to raise_error(Payload::NotFound)
    end
  end
end

