require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Transaction Integration Tests' do
  include_context 'test helpers'

  describe 'Transactions' do
    let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }
    it 'has empty transaction ledger' do
      proc_account = create_processing_account(session)
      card_payment = create_card_payment(proc_account.id, session)
      transaction = session.Transaction.select('*', 'ledger').get(card_payment.id)
      expect(transaction.ledger).to eq([])
    end

    it 'tests unified payout batching' do
      proc_account = create_processing_account(session)
      create_blind_refund(session, 10, proc_account.id)

      transactions = session.Transaction.select('*', 'ledger')
        .filter_by(type: 'refund', processing_id: proc_account.id)
        .all

      expect(transactions.length).to eq(1)
      expect(transactions[0].processing_id).to eq(proc_account.id)
    end

    it 'gets transactions' do
      proc_account = create_processing_account(session)
      create_card_payment(proc_account.id, session)
      payments = session.Transaction.filter_by(status: 'processed', type: 'payment').all
      expect(payments.length).to be > 0
    end

    it 'checks risk flag' do
      proc_account = create_processing_account(session)
      card_payment = create_card_payment(proc_account.id, session)
      expect(card_payment.risk_flag).to eq('allowed')
    end

    it 'updates processed transaction' do
      proc_account = create_processing_account(session)
      card_payment = create_card_payment(proc_account.id, session)
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

