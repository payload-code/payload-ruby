require 'payload'
require 'date'

RSpec.shared_context 'test helpers' do
  before(:all) do
    Payload.api_key = ENV['TEST_SECRET_KEY']
    if ENV['TEST_API_URL']
      Payload.api_url = ENV['TEST_API_URL']
    end
  end

  def create_customer_account
    Payload::Customer.create(name: 'Test', email: 'test@example.com')
  end

  def create_processing_account
    Payload::ProcessingAccount.create(
      name: 'Processing Account',
      legal_entity: {
        legal_name: 'Test',
        type: 'INDIVIDUAL_SOLE_PROPRIETORSHIP',
        ein: '23 423 4234',
        street_address: '123 Example Street',
        unit_number: 'Suite 1',
        city: 'New York',
        state_province: 'NY',
        state_incorporated: 'NY',
        postal_code: '11238',
        country: 'US',
        phone_number: '(111) 222-3333',
        website: 'http://www.payload.com',
        start_date: '05/01/2015',
        contact_name: 'Test Person',
        contact_email: 'test.person@example.com',
        contact_title: 'VP',
        owners: [
          {
            full_name: 'Test Person',
            email: 'test.person@example.com',
            ssn: '234 23 4234',
            birth_date: '06/20/1985',
            title: 'CEO',
            ownership: '100',
            street_address: '123 Main Street',
            unit_number: '#1A',
            city: 'New York',
            state_province: 'NY',
            postal_code: '10001',
            phone_number: '(111) 222-3333',
            type: 'owner'
          }
        ]
      },
      payment_methods: {
        type: 'bank_account',
        bank_account: {
          account_number: '123456789',
          routing_number: '036001808',
          account_type: 'checking'
        }
      }
    )
  end

  def create_card_payment(processing_account)
    Payload::Payment.create(
      processing_id: processing_account.id,
      amount: rand * 100,
      payment_method: {
        type: 'card',
        card: {
          card_number: '4242 4242 4242 4242',
          expiry: '12/35',
          card_code: '123',
        },
        billing_address: { 
          postal_code: '11111'
        }
      }
    )
  end

  def create_bank_payment
    Payload::Payment.create(
      type: 'payment',
      amount: rand * 1000,
      payment_method: {
        type: 'bank_account',
        account_holder: 'First Last',
        bank_account: {
          account_number: '1234567890',
          routing_number: '036001808',
          account_type: 'checking'
        },
        billing_address: { 
          postal_code: '11111'
        }
      }
    )
  end

  def create_payment_link_one_time(processing_account)
    Payload::PaymentLink.create(
      type: 'one_time',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end

  def create_payment_link_reusable(processing_account)
    Payload::PaymentLink.create(
      type: 'reusable',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end

  def create_invoice(processing_account, customer_account)
    Payload::Invoice.create(
      type: 'bill',
      processing_id: processing_account.id,
      due_date: Date.today.strftime('%Y-%m-%d'),
      customer_id: customer_account.id,
      items: [Payload::ChargeItem.new(amount: 29.99)]
    )
  end
end

