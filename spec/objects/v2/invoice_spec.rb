require 'payload'
require 'payload/arm/object'
require 'date'
require_relative '../../support/helpers'

RSpec.describe 'Invoice Integration Tests - V2' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 2) }
  let(:h) { V2Helpers.new(session) }

  let(:proc_account)       { h.create_processing_account }
  let(:customer_account)   { h.create_customer_account }
  let(:invoice)            { h.create_invoice(proc_account, customer_account) }

  describe 'Invoice' do
    it 'creates an invoice' do
      inv = invoice
      expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
      expect(inv.status).to eq('unpaid')
    end

    it 'pays an invoice' do
      inv = invoice
      expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
      expect(inv.status).to eq('unpaid')

      amount = inv.totals['balance_due']

      if inv.status != 'paid'
        h.create_card_payment(
          proc_account.id,
          amount: amount,
          description: 'Test Payment',
          customer_id: customer_account.id,
          invoice_id: inv.id
        )
      end

      get_invoice = session.Invoice.get(inv.id)
      expect(get_invoice.status).to eq('paid')
    end

    it 'deletes an invoice' do
      inv = invoice
      inv.delete

      expect {
        session.Invoice.get(inv.id)
      }.to raise_error(Payload::NotFound)
    end
  end
end
