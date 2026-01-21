class V1Helpers
  attr_reader :session

  def initialize(session)
    @session = session
  end

  def create_customer_account(name: 'Test', email: 'test@example.com')
    session.Customer.create(name: name, email: email)
  end

  def create_processing_account
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

  def create_card_payment(processing_id, amount: nil, description: nil, customer_id: nil, invoice_id: nil)
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
    session.Payment.create(payment)
  end

  def create_bank_payment
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

  def create_invoice(processing_account, customer_account)
    session.Invoice.create(
      processing_id: processing_account.id,
      due_date: Date.today.strftime('%Y-%m-%d'),
      customer_id: customer_account.id,
      items: [session.ChargeItem.new(amount: 29.99)]
    )
  end

  def create_blind_refund(amount, processing_id)
    session.Refund.create(
      amount: amount,
      processing_id: processing_id,
      payment_method: {
        type: 'card',
        card: {
          card_number: '4242 4242 4242 4242',
          expiry: '12/30',
          card_code: '123'
        },
        billing_address: { postal_code: '11111' }
      }
    )
  end

  def create_refund(payment, amount: nil)
    session.Refund.create(
      amount: amount || payment.amount,
      ledger: [{assoc_transaction_id: payment.id}]
    )
  end

  def create_payment_link_one_time(processing_account)
    session.PaymentLink.create(
      type: 'one_time',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end

  def create_payment_link_reusable(processing_account)
    session.PaymentLink.create(
      type: 'reusable',
      description: 'Payment Request',
      amount: 10.00,
      processing_id: processing_account.id
    )
  end
end
