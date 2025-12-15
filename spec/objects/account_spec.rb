require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Account Integration Tests' do
  include_context 'test helpers'

  describe 'Customer Account' do
    [1, 2]
    .each do |api_version|
      context "api_version=#{api_version}" do
        let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, api_version) }

        it 'creates a customer account' do
          customer_account = create_customer_account(session)
          expect(customer_account.id).to be_truthy
        end

        it 'deletes a customer account' do
          cust_account = create_customer_account(session)
          cust_account.delete
          
          expect {
            session.Customer.get(cust_account.id) if api_version == 1
            session.Account.get(cust_account.id) if api_version == 2
          }.to raise_error(Payload::NotFound)
        end

        it 'creates multiple accounts' do
          rand_email1 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'
          rand_email2 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'

          name1 = 'Matt Perez'
          name2 = 'Andrea Kearney'

          accounts_to_create = []
          if api_version == 1
            accounts_to_create << session.Customer.new(email: rand_email1, name: name1)
            accounts_to_create << session.Customer.new(email: rand_email2, name: name2)
          else
            accounts_to_create << session.Account.new(type: 'customer', contact_details: { email: rand_email1 }, name: name1)
            accounts_to_create << session.Account.new(type: 'customer', contact_details: { email: rand_email2 }, name: name2)
          end
          session.create(accounts_to_create)

          if api_version == 1
            get_account_1 = session.Customer.filter_by(email: rand_email1).all[0]
            get_account_2 = session.Customer.filter_by(email: rand_email2).all[0]
          else
            get_account_1 = session.Account.filter_by(type: 'customer', 'contact_details[email]': rand_email1 ).all[0]
            get_account_2 = session.Account.filter_by(type: 'customer', 'contact_details[email]': rand_email2 ).all[0]
          end

          expect(get_account_1).to be_truthy
          expect(get_account_2).to be_truthy
        end

        it 'gets a processing account' do
          proc_account = create_processing_account(session)
          retrieved = session.ProcessingAccount.get(proc_account.id) if api_version == 1
          retrieved = session.Account.get(proc_account.id) if api_version == 2
          expect(retrieved).to be_truthy
          expect(proc_account.status).to eq('pending') if api_version == 1
          expect(proc_account.processing['status']['funding']).to eq('pending') if api_version == 2
        end

        it 'pages and orders results' do
          accounts_to_create = []
          if api_version == 1
            accounts_to_create << session.Customer.new(email: 'account1@example.com', name: 'Randy Robson')
            accounts_to_create << session.Customer.new(email: 'account2@example.com', name: 'Brandy Bobson')
            accounts_to_create << session.Customer.new(email: 'account3@example.com', name: 'Mandy Johnson')
          else
            accounts_to_create << session.Account.new(type: 'customer', contact_details: { email: 'account1@example.com' }, name: 'Randy Robson')
            accounts_to_create << session.Account.new(type: 'customer', contact_details: { email: 'account2@example.com' }, name: 'Brandy Bobson')
            accounts_to_create << session.Account.new(type: 'customer', contact_details: { email: 'account3@example.com' }, name: 'Mandy Johnson')
          end
          session.create(accounts_to_create)
          if api_version == 1 
            customers = session.Customer.filter_by(order_by: 'created_at', limit: 3, offset: 1).all
          else
            customers = session.Account.filter_by(type: 'customer', order_by: 'created_at', limit: 3, offset: 1).all
          end

          expect(customers.length).to eq(3)
          require 'time'
          expect(Time.parse(customers[0].created_at)).to be <= Time.parse(customers[1].created_at)
          expect(Time.parse(customers[1].created_at)).to be <= Time.parse(customers[2].created_at)
        end

        it 'updates a customer' do
          cust_account = create_customer_account(session)
          cust_account.update(email: 'test2@example.com') if api_version == 1
          cust_account.update(contact_details: { email: 'test2@example.com' }) if api_version == 2
          expect(cust_account.email).to eq('test2@example.com') if api_version == 1
          expect(cust_account.contact_details['email']).to eq('test2@example.com') if api_version == 2
        end

        it 'updates multiple accounts' do
          customer_account_1 = create_customer_account(session, name: 'Brandy', email: 'test1@example.com')
          customer_account_2 = create_customer_account(session, name: 'Sandy', email: 'test2@example.com')
          if api_version == 1
            updated_accounts = session.update([
              [customer_account_1, { email: 'brandy@example.com' }],
              [customer_account_2, { email: 'sandy@example.com' }]
            ])
          else
            updated_accounts = session.update([
              [customer_account_1, { contact_details: { email: 'brandy@example.com' } }],
              [customer_account_2, { contact_details: { email: 'sandy@example.com' } }]
            ])
          end

          expect(updated_accounts[0].email).to eq('brandy@example.com') if api_version == 1
          expect(updated_accounts[0].contact_details['email']).to eq('brandy@example.com') if api_version == 2
          expect(updated_accounts[1].email).to eq('sandy@example.com') if api_version == 1
          expect(updated_accounts[1].contact_details['email']).to eq('sandy@example.com') if api_version == 2
        end

        it 'gets a customer' do
          cust_account = create_customer_account(session)
          if api_version == 1
            expect(session.Customer.get(cust_account.id)).to be_truthy
          else
            expect(session.Account.get(cust_account.id)).to be_truthy
          end
        end

        it 'selects customer attributes' do
          cust_account = create_customer_account(session)
          if api_version == 1
            selected = session.Customer.select('id').get(cust_account.id)
          else
            selected = session.Account.select('id').get(cust_account.id)
          end
          expect(selected['id']).to eq(cust_account.id)
        end
      end
    end
  end
end

