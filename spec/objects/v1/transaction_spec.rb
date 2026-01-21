require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Transaction Integration Tests - V1' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }
  let(:h) { V1Helpers.new(session) }
  let(:proc_account) { h.create_processing_account }

  describe 'Transactions' do

    it 'has empty transaction ledger' do
      card_payment = h.create_card_payment(proc_account.id)
      transaction = session.Transaction.select('*', 'ledger').get(card_payment.id)
      expect(transaction.ledger).to eq([])
    end

    it 'tests unified payout batching' do
      h.create_blind_refund(10, proc_account.id)

      transactions = session.Transaction.select('*', 'ledger')
        .filter_by(type: 'refund', processing_id: proc_account.id)
        .all

      expect(transactions.length).to eq(1)
      expect(transactions[0].processing_id).to eq(proc_account.id)
    end

    it 'gets transactions' do
      h.create_card_payment(proc_account.id)
      payments = session.Transaction.filter_by(status: 'processed', type: 'payment').all
      expect(payments.length).to be > 0
    end

    it 'checks risk flag' do
      card_payment = h.create_card_payment(proc_account.id)
      expect(card_payment.risk_flag).to eq('allowed')
    end

    it 'updates processed transaction' do
      card_payment = h.create_card_payment(proc_account.id)
      card_payment.update(status: 'voided')
      expect(card_payment.status).to eq('voided')
    end

    it 'raises error for transaction not found' do
      expect {
        session.Transaction.get('invalid')
      }.to raise_error(Payload::NotFound)
    end
  end
end

