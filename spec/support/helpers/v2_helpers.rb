class V2Helpers
  attr_reader :session

  def initialize(session)
    @session = session
  end

  def create_customer_account(name: 'Test', email: 'test@example.com')
    session.Account.create(
      type: 'customer',
      name: name,
      contact_details: {
        email: email
      }
    )
  end

  def create_processing_account
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
            email: 'johnsmith@gmail.com',
          },
          stakeholders: [
            {
              country: 'US',
              personal_information: {
                full_name:    'John Smith',
                email:        'johnsmith@gmail.com',
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
              association: {
                ownership: {
                  percentage:  100,
                  years_owned: 5,
                },
                roles: ['principal_officer'],
                title: 'CEO',
              },
            },
          ],
        },
      },
    )
  end

  def create_card_payment(processing_id, amount: nil, description: nil, customer_id: nil, invoice_id: nil)
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
    if processing_id
      payment = payment.merge({
        receiver: {
          account_id: processing_id,
        }
      })
    end
    session.Transaction.create(payment)
  end

  def create_bank_payment
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

  def create_invoice(processing_account, customer_account)
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

  def create_blind_refund(amount, processing_id)
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
            expiry: '12/30',
            card_code: '123'
          },
          billing_address: { postal_code: '11111' }
        )
      }
    )
  end

  def create_refund(payment, amount: nil)
    session.Transaction.create(
      type: 'refund',
      transfers: [{assoc_transaction_id: payment.id, amount: amount || payment.amount}]
    )
  end
end
