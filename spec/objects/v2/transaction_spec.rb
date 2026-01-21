require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Transaction Integration Tests - V2' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 2) }
  let(:h) { V2Helpers.new(session) }
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
    end

    it 'gets transactions' do
      h.create_card_payment(proc_account.id)
      payments = session.Transaction.filter_by('status[value]': 'processed', type: 'payment', 'receiver[account_id]': proc_account.id).all
      expect(payments.length).to be > 0
    end

    it 'updates processed transaction' do
      card_payment = h.create_card_payment(proc_account.id)
      card_payment.update(status: { value: 'voided' })
      expect(card_payment.status['value']).to eq('voided')
    end

    it 'raises error for transaction not found' do
      expect {
        session.Transaction.get('invalid')
      }.to raise_error(Payload::NotFound)
    end
  end
end
