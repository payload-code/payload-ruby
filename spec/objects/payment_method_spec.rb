require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Payment Method Integration Tests' do
  include_context 'test helpers'

  describe 'Payment Methods' do
    [1, 2]
    .each do |api_version|
      context "api_version=#{api_version}" do
        let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, api_version) }
  
        it 'creates a payment with card' do
          proc_account = create_processing_account(session)
          card_payment = create_card_payment(proc_account, session)
          status = api_version == 1 ? card_payment.status : card_payment.status['value']
          expect(status).to eq('processed')
        end
        it 'creates a payment with bank account' do
          bank_payment = create_bank_payment(session)
          status = api_version == 1 ? bank_payment.status : bank_payment.status['value']
          expect(status).to eq('processed')
        end
        it 'filters payments' do
          proc_account = create_processing_account(session)
          rand_description = (0...10).map { ('a'..'z').to_a[rand(26)] }.join
    
          amounts = [90.0, 100.0, 110.0]
          card_payments = []
          amounts.each do |amount|
            card_payment = create_card_payment(proc_account, session, amount: amount, description: rand_description)
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
          proc_account = create_processing_account(session)
          card_payment = create_card_payment(proc_account, session)
          card_payment.update(status: 'voided') if api_version == 1
          card_payment.update(status: { value: 'voided' }) if api_version == 2
          status = api_version == 1 ? card_payment.status : card_payment.status['value']
          expect(status).to eq('voided')
        end
    
        it 'voids a bank payment' do
          bank_payment = create_bank_payment(session)
          bank_payment.update(status: 'voided') if api_version == 1
          bank_payment.update(status: { value: 'voided' }) if api_version == 2
          status = api_version == 1 ? bank_payment.status : bank_payment.status['value']
          expect(status).to eq('voided')
        end
    
        it 'refunds a card payment' do
          proc_account = create_processing_account(session)
          card_payment = create_card_payment(proc_account, session)
          refund = create_refund(session, card_payment)
    
          expect(refund.type).to eq('refund')
          expect(refund.amount).to eq(card_payment.amount)
        end
    
        it 'partially refunds a card payment' do
          proc_account = create_processing_account(session)
          card_payment = create_card_payment(proc_account, session)
          amount = (card_payment.amount/2).round(2) # rounded to 2 decimal places
          refund = create_refund(session, card_payment, amount: amount)
    
          expect(refund.type).to eq('refund')
          expect(refund.amount).to eq(amount)
        end
    
        it 'creates a blind refund for card payment' do
          proc_account = create_processing_account(session) 
          refund = create_blind_refund(session, 10, proc_account.id)
    
          expect(refund.type).to eq('refund')
          expect(refund.amount).to eq(10)
        end
    
        it 'refunds a bank payment' do
          bank_payment = create_bank_payment(session)
          refund = create_refund(session, bank_payment)
    
          expect(refund.type).to eq('refund')
          expect(refund.amount).to eq(bank_payment.amount)
        end
    
        it 'partially refunds a bank payment' do
          bank_payment = create_bank_payment(session)
          amount = (bank_payment.amount/2).round(2) # rounded to 2 decimal places
          refund = create_refund(session, bank_payment, amount: amount)
    
          expect(refund.type).to eq('refund')
          expect(refund.amount).to eq(amount)
        end
    
        it 'raises error for invalid payment method type' do
          expect {
            session.Transaction.create(
              type: 'invalid',
              card_number: '4242 4242 4242 4242',
              expiry: '12/25'
            )
          }.to raise_error(Payload::InvalidAttributes)
        end
      end
    end
  end
end

