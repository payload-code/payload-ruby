require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Account Integration Tests - V2' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 2) }

  describe 'Customer Account' do
    it 'creates a customer account' do
      customer_account = session.Account.create(
        type: 'customer',
        name: 'Test',
        contact_details: {
          email: 'test@example.com'
        }
      )
      expect(customer_account.id).to be_truthy
    end

    it 'deletes a customer account' do
      cust_account = session.Account.create(
        type: 'customer',
        name: 'Test',
        contact_details: {
          email: 'test@example.com'
        }
      )
      cust_account.delete

      expect {
        session.Account.get(cust_account.id)
      }.to raise_error(Payload::NotFound)
    end

    it 'creates multiple accounts' do
      rand_email1 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'
      rand_email2 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'

      name1 = 'Matt Perez'
      name2 = 'Andrea Kearney'

      accounts_to_create = [
        session.Account.new(type: 'customer', contact_details: { email: rand_email1 }, name: name1),
        session.Account.new(type: 'customer', contact_details: { email: rand_email2 }, name: name2)
      ]
      session.create(accounts_to_create)

      get_account_1 = session.Account.filter_by(type: 'customer', 'contact_details[email]': rand_email1).all[0]
      get_account_2 = session.Account.filter_by(type: 'customer', 'contact_details[email]': rand_email2).all[0]

      expect(get_account_1).to be_truthy
      expect(get_account_2).to be_truthy
    end

    it 'gets a processing account' do
      orgs = session.Profile.all()
      org = orgs[0]
      proc_account = session.Account.create(
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
                association: {
                  roles: ['principal_officer'],
                  title: 'CEO',
                  ownership: {
                    percentage:  100,
                    years_owned: 5,
                  },
                },
              },
            ],
          },
        },
      )
      retrieved = session.Account.get(proc_account.id)
      expect(retrieved).to be_truthy
      expect(proc_account.processing['status']['funding']).to eq('pending')
    end

    it 'pages and orders results' do
      accounts_to_create = [
        session.Account.new(type: 'customer', contact_details: { email: 'account1@example.com' }, name: 'Randy Robson'),
        session.Account.new(type: 'customer', contact_details: { email: 'account2@example.com' }, name: 'Brandy Bobson'),
        session.Account.new(type: 'customer', contact_details: { email: 'account3@example.com' }, name: 'Mandy Johnson')
      ]
      session.create(accounts_to_create)
      customers = session.Account.filter_by(type: 'customer', order_by: 'created_at', limit: 3, offset: 1).all

      expect(customers.length).to eq(3)
      require 'time'
      expect(Time.parse(customers[0].created_at)).to be <= Time.parse(customers[1].created_at)
      expect(Time.parse(customers[1].created_at)).to be <= Time.parse(customers[2].created_at)
    end

    it 'updates a customer' do
      cust_account = session.Account.create(
        type: 'customer',
        name: 'Test',
        contact_details: {
          email: 'test@example.com'
        }
      )
      cust_account.update(contact_details: { email: 'test2@example.com' })
      expect(cust_account.contact_details['email']).to eq('test2@example.com')
    end

    it 'updates multiple accounts' do
      customer_account_1 = session.Account.create(
        type: 'customer',
        name: 'Brandy',
        contact_details: { email: 'test1@example.com' }
      )
      customer_account_2 = session.Account.create(
        type: 'customer',
        name: 'Sandy',
        contact_details: { email: 'test2@example.com' }
      )
      updated_accounts = session.update([
        [customer_account_1, { contact_details: { email: 'brandy@example.com' } }],
        [customer_account_2, { contact_details: { email: 'sandy@example.com' } }]
      ])

      expect(updated_accounts[0].contact_details['email']).to eq('brandy@example.com')
      expect(updated_accounts[1].contact_details['email']).to eq('sandy@example.com')
    end

    it 'gets a customer' do
      cust_account = session.Account.create(
        type: 'customer',
        name: 'Test',
        contact_details: {
          email: 'test@example.com'
        }
      )
      expect(session.Account.get(cust_account.id)).to be_truthy
    end

    it 'selects customer attributes' do
      cust_account = session.Account.create(
        type: 'customer',
        name: 'Test',
        contact_details: {
          email: 'test@example.com'
        }
      )
      selected = session.Account.select('id').get(cust_account.id)
      expect(selected['id']).to eq(cust_account.id)
    end
  end
end
