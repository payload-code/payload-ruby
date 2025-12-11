require 'payload'
require 'payload/arm/object'
require_relative '../support/helpers'

RSpec.describe 'Account Integration Tests' do
  include_context 'test helpers'

  describe 'Customer Account' do
    it 'creates a customer account' do
      customer_account = Payload::Customer.create(name: 'Test', email: 'test@example.com')
      expect(customer_account.id).to be_truthy
    end

    it 'deletes a customer account' do
      cust_account = create_customer_account
      cust_account.delete
      
      expect {
        Payload::Customer.get(cust_account.id)
      }.to raise_error(Payload::NotFound)
    end

    it 'creates multiple accounts' do
      rand_email1 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'
      rand_email2 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'

      accounts = Payload.create([
        Payload::Customer.new(email: rand_email1, name: 'Matt Perez'),
        Payload::Customer.new(email: rand_email2, name: 'Andrea Kearney')
      ])

      get_account_1 = Payload::Customer.filter_by(email: rand_email1).all[0]
      get_account_2 = Payload::Customer.filter_by(email: rand_email2).all[0]

      expect(get_account_1).to be_truthy
      expect(get_account_2).to be_truthy
    end

    it 'gets a processing account' do
      proc_account = create_processing_account
      retrieved = Payload::ProcessingAccount.get(proc_account.id)
      expect(retrieved).to be_truthy
      expect(proc_account.status).to eq('pending')
    end

    it 'pages and orders results' do
      Payload.create([
        Payload::Customer.new(email: 'account1@example.com', name: 'Randy Robson'),
        Payload::Customer.new(email: 'account2@example.com', name: 'Brandy Bobson'),
        Payload::Customer.new(email: 'account3@example.com', name: 'Mandy Johnson')
      ])

      customers = Payload::Customer.filter_by(order_by: 'created_at', limit: 3, offset: 1).all

      expect(customers.length).to eq(3)
      require 'time'
      expect(Time.parse(customers[0].created_at)).to be <= Time.parse(customers[1].created_at)
      expect(Time.parse(customers[1].created_at)).to be <= Time.parse(customers[2].created_at)
    end

    it 'updates a customer' do
      cust_account = create_customer_account
      cust_account.update(email: 'test2@example.com')
      expect(cust_account.email).to eq('test2@example.com')
    end

    it 'updates multiple accounts' do
      customer_account_1 = Payload::Customer.create(name: 'Brandy', email: 'test1@example.com')
      customer_account_2 = Payload::Customer.create(name: 'Sandy', email: 'test2@example.com')

      updated_accounts = Payload.update([
        [customer_account_1, { email: 'brandy@example.com' }],
        [customer_account_2, { email: 'sandy@example.com' }]
      ])

      expect(updated_accounts[0].email).to eq('brandy@example.com')
      expect(updated_accounts[1].email).to eq('sandy@example.com')
    end

    it 'gets a customer' do
      cust_account = create_customer_account
      expect(Payload::Customer.get(cust_account.id)).to be_truthy
    end

    it 'selects customer attributes' do
      cust_account = create_customer_account
      selected = Payload::Customer.select('id').get(cust_account.id)
      expect(selected['id']).to eq(cust_account.id)
    end
  end
end

