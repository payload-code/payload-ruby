require 'payload'
require 'date'

RSpec.shared_context 'test helpers' do
  before(:all) do
    Payload.api_key = ENV['TEST_SECRET_KEY']
    if ENV['TEST_API_URL']
      Payload.api_url = ENV['TEST_API_URL']
    end
  end

  def create_customer_account(session, name: 'Test', email: 'test@example.com')
    if session.api_version == 2
      create_customer_account_v2(session, name: name, email: email)
    else
      create_customer_account_v1(session, name: name, email: email)
    end
  end

  def create_processing_account(session)
    if session.api_version == 2
      create_processing_account_v2(session)
    else
      create_processing_account_v1(session)
    end
  end

  def create_card_payment(processing_id, session, amount: nil, description: nil, customer_id: nil, invoice_id: nil)
    if session.api_version == 2
      sender = {
        method: session.PaymentMethod.new(
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
              expiry: '12/35',
              card_code: '123',
            },
          billing_address: {
            postal_code: '11111'
          }
        )
      }
      if customer_id
        sender = sender.merge({
          account_id: customer_id,
        })
      end
      payment = {
        type: 'payment',
        amount: amount || rand * 100,
        description: description || 'Test Payment',
        sender: sender,
      }
      if invoice_id
        payment = payment.merge({
          invoice_allocations: [{invoice_id: invoice_id}]
        })
      end
      session.Transaction.create(
        payment
      )
    else  
      payment = {
        processing_id: processing_id,
        amount: amount || rand * 100,
        description: description || 'Test Payment',
        payment_method: session.PaymentMethod.new(
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
            expiry: '12/35',
            card_code: '123',
          },
          billing_address: {
            postal_code: '11111'
          }
        )
      }
      if invoice_id
        payment = payment.merge({
          allocations: [{invoice_id: invoice_id}]
        })
      end
      if customer_id
        payment = payment.merge({
          customer_id: customer_id
        })
      end
      session.Payment.create(
        payment
      )
    end
  end

  def create_bank_payment(session)
    if session.api_version == 2
      create_bank_payment_v2(session)
    else
      create_bank_payment_v1(session)
    end
  end

  def create_payment_link_one_time(processing_account, session)
    session.PaymentLink.create(
      type: 'one_time',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end

  def create_payment_link_reusable(processing_account, session)
    session.PaymentLink.create(
      type: 'reusable',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end

  def create_invoice(processing_account, customer_account, session)
    if session.api_version == 2
      create_invoice_v2(processing_account, customer_account, session)
    else
      create_invoice_v1(processing_account, customer_account, session)
    end
  end

  def create_blind_refund(session, amount, processing_id)
    if session.api_version == 2
      create_blind_refund_v2(session, amount, processing_id)
    else  
      create_blind_refund_v1(session, amount, processing_id)
    end
  end

  def create_refund(session, payment, amount: nil)
    if session.api_version == 2
        session.Transaction.create(
          type: 'refund',
          transfers: [{assoc_transaction_id: payment.id, amount: amount || payment.amount}]
        )
    else
      session.Refund.create(
        amount: amount || payment.amount,
        ledger: [{assoc_transaction_id: payment.id}]
      )
    end
  end

  private

  def create_processing_account_v1(session)
    session.ProcessingAccount.create(
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
      payment_methods: [session.PaymentMethod.new(
        type: 'bank_account',
        bank_account: {
          account_number: '123456789',
          routing_number: '036001808',
          account_type: 'checking'
        }
      )]
    )
  end

  def create_processing_account_v2(session)
    org = session.Profile.all()[0]
    session.Account.create(
      type: 'processing',
      name: 'Processing Account',
      processing: {
        status:      { funding: 'pending' },
        settings_id: org.processing_settings_id,
      },
      payment_methods: [session.PaymentMethod.new(
        type: 'bank_account',
        bank_account: {
          account_number: '123456789',
          routing_number: '036001808',
          account_type:   'checking'
        },
        billing_address: {
          postal_code: '11111',
        },
        account_defaults: {
          funding: 'all',
        }
      )],
      entity: {
        type:        'business',
        legal_name:  'Example',
        country:     'US',
        phone_number: '123 123-1234',
        tax_id:      { value: '123 12 1234' },
        address: {
          address_line_1: '123 Example St',
          city:           'New York',
          state_province: 'NY',
          postal_code:    '11111',
        },
        business: {
          category: 'real_estate',
          structure: 'llc',
          website:  'https://example.com',
          formation: {
            state_province: 'NY',
            date:           '2019-10-01',
          },
          primary_contact: {
            name:  'John Smith',
            title: 'CEO',
            email: 'johnsmith@gmail.com',
          },
          stakeholders: [
            {
              country: 'US',
              personal_information: {
                full_name:    'John Smith',
                email:        'johnsmith@gmail.com',
                title:        'CEO',
                birth_date:   '1990-05-10',
                phone_number: '123 123-1234',
              },
              address: {
                address_line_1: '123 Example St',
                city:           'New York',
                state_province: 'NY',
                postal_code:    '11111',
              },
              govt_id: {
                tax_id: { value: '123 12 1234' },
              },
              ownership: {
                percentage:  100,
                years_owned: 5,
              },
            },
          ],
        },
      },
    )
  end

  def create_bank_payment_v1(session)
    session.Payment.create(
      type: 'payment',
      amount: rand * 1000,
      payment_method: session.PaymentMethod.new(
        type: 'bank_account',
        account_holder: 'First Last',
        bank_account: {
          account_number: '1234567890',
          routing_number: '036001808',
          account_type:   'checking'
        },
        billing_address: {
          postal_code: '11111'
        }
      )
    )
  end

  def create_bank_payment_v2(session)
    session.Transaction.create(
      type: 'payment',
      amount: rand * 1000,
      sender: {
          method: session.PaymentMethod.new(
          type: 'bank_account',
          account_holder: 'First Last',
          bank_account: {
            account_number: '123456789',
            currency:       'USD',
            routing_number: '036001808',
            account_type:   'checking',
            account_class:  'personal',
          },
        )
      }
    )
  end

  def create_blind_refund_v2(session, amount, processing_id)
    session.Transaction.create(
      type: 'refund',
      amount: amount,
      sender: {
        account_id: processing_id,
      },
      receiver: {
        method: session.PaymentMethod.new(
          type: 'card',
          card: {
            card_number: '4242 4242 4242 4242',
            expiry: '12/25',
            card_code: '123'
          },
          billing_address: { postal_code: '11111' }
        )
      }
    )
  end

  def create_blind_refund_v1(session, amount, processing_id)
    session.Refund.create(
      amount: amount,
      processing_id: processing_id,
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
  end

  def create_invoice_v1(processing_account, customer_account, session)
    session.Invoice.create(
      processing_id: processing_account.id,
      due_date: Date.today.strftime('%Y-%m-%d'),
      customer_id: customer_account.id,
      items: [session.ChargeItem.new(amount: 29.99)]
    )
  end

  def create_invoice_v2(processing_account, customer_account, session)
    session.Invoice.create(
      due_date: Date.today.strftime('%Y-%m-%d'),
      biller: {
        account_id: processing_account.id,
      },
      payer: {
        account_id: customer_account.id,
      },
      items: [
        {
          type: 'line_item',
          line_item: {
            value: 29.99,
          }
        }
      ],
    )
  end

  def create_customer_account_v1(session, name: 'Test', email: 'test@example.com')
    session.Customer.create(name: name, email: email)
  end

  def create_customer_account_v2(session, name: 'Test', email: 'test@example.com')
    session.Account.create(
      type: 'customer',
      name: name,
      contact_details: {
        email: email
      }
    )
  end
end

