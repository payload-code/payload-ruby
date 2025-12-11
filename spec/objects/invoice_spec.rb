require 'payload'
require 'payload/arm/object'
require 'date'
require_relative '../support/helpers'

RSpec.describe 'Invoice Integration Tests' do
  include_context 'test helpers'

  describe 'Invoice' do
    let(:invoice) do
      proc_account = create_processing_account
      customer_account = create_customer_account
      Payload::Invoice.create(
        type: 'bill',
        processing_id: proc_account.id,
        due_date: Date.today.strftime('%Y-%m-%d'),
        customer_id: customer_account.id,
        items: [{amount: 29.99, entry_type: 'charge'}]
      )
    end

    it 'creates an invoice' do
      inv = invoice
      expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
      expect(inv.status).to eq('unpaid')
    end

    it 'pays an invoice' do
      inv = invoice
      customer_account = create_customer_account
      expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
      expect(inv.status).to eq('unpaid')

      # card_payment = Payload::Card.create(
      #   account_id: customer_account.id,
      #   card_number: '4242 4242 4242 4242',
      #   expiry: '12/35',
      #   card_code: '123',
      #   billing_address: { postal_code: '11111' }
      # )

      if inv.status != 'paid'
        Payload::Payment.create(
          amount: inv.amount_due,
          customer_id: customer_account.id,
          payment_method: {
            type: 'card',
            card: {
              card_number: '4242 4242 4242 4242',
              expiry: '12/35',
              card_code: '123',
            },
            billing_address: { postal_code: '11111' }
          },
          allocations: [{entry_type: 'payment', invoice_id: inv.id}]
        )
      end

      get_invoice = Payload::Invoice.get(inv.id)
      expect(get_invoice.status).to eq('paid')
    end

    it 'deletes an invoice' do
      inv = invoice
      inv.delete
      
      expect {
        Payload::Invoice.get(inv.id)
      }.to raise_error(Payload::NotFound)
    end
  end
end

