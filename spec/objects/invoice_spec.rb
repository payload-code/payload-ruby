require 'payload'
require 'payload/arm/object'
require 'date'
require_relative '../support/helpers'

RSpec.describe 'Invoice Integration Tests' do
  include_context 'test helpers'

  describe 'Invoice' do
    [1, 2]
    .each do |api_version|
      context "api_version=#{api_version}" do
        let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, api_version) }

        let(:proc_account)       { create_processing_account(session) }
        let(:customer_account)   { create_customer_account(session) }
        let(:invoice)            { create_invoice(proc_account, customer_account, session) }

        it 'creates an invoice' do
          inv = invoice
          expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
          expect(inv.status).to eq('unpaid')
        end

        it 'pays an invoice' do
          inv = invoice
          expect(inv.due_date).to eq(Date.today.strftime('%Y-%m-%d'))
          expect(inv.status).to eq('unpaid')

          # card_payment = Payload::Card.create(
          #   account_id: customer_account.id,
          #   card_number: '4242 4242 4242 4242',
          #   expiry: '12/35',
          #   card_code: '123',
          #   billing_address: { postal_code: '11111' }
          # )
          
          if session.api_version == 1
            amount = inv.amount_due
          else
            puts "inv.totals: #{inv.totals.inspect}"
            amount = inv.totals['balance_due']
          end

          if inv.status != 'paid'
            create_card_payment(
              proc_account.id, 
              session, 
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
  end
end

