require 'payload'
require 'payload/arm/object'
require 'payload/arm/session'
require 'date'
require_relative '../support/helpers'

RSpec.describe 'Session Integration Tests' do
  include_context 'test helpers'

  describe 'Session' do
    let(:pl) do
      Payload.api_key = nil
      session = Payload::Session.new(ENV['TEST_SECRET_KEY'])
      if ENV['TEST_API_URL']
        session.api_url = ENV['TEST_API_URL']
      end
      session
    end

    it 'creates a customer account with session' do
      customer_account = pl.Customer.create(name: 'Test', email: 'test@example.com')
      expect(customer_account.id).to be_truthy
    end

    it 'deletes with session' do
      customer_account = pl.Customer.create(name: 'Test', email: 'test@example.com')
      customer_account.delete
      
      expect {
        customer_get = pl.Customer.get(customer_account.id)
      }.to raise_error(Payload::NotFound)
    end

    it 'creates multiple accounts with session' do
      rand_email1 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'
      rand_email2 = (0...5).map { ('a'..'z').to_a[rand(26)] }.join + '@example.com'

      accounts = pl.create([
        pl.Customer.new(email: rand_email1, name: 'Matt Perez'),
        pl.Customer.new(email: rand_email2, name: 'Andrea Kearney')
      ])

      get_account_1 = pl.Customer.filter_by(email: rand_email1).all[0]
      get_account_2 = pl.Customer.filter_by(email: rand_email2).all[0]

      expect(get_account_1).to be_truthy
      expect(get_account_2).to be_truthy
    end

    it 'pages and orders results with session' do
      pl.create([
        pl.Customer.new(email: 'account1@example.com', name: 'Randy Robson'),
        pl.Customer.new(email: 'account2@example.com', name: 'Brandy Bobson'),
        pl.Customer.new(email: 'account3@example.com', name: 'Mandy Johnson')
      ])

      customers = pl.Customer.filter_by(order_by: 'created_at', limit: 3, offset: 1).all

      expect(customers.length).to eq(3)
      require 'time'
      expect(Time.parse(customers[0].created_at)).to be <= Time.parse(customers[1].created_at)
      expect(Time.parse(customers[1].created_at)).to be <= Time.parse(customers[2].created_at)
    end

    it 'updates customer with session' do
      customer_account = pl.Customer.create(name: 'Test', email: 'test@example.com')
      customer_account.update(email: 'test2@example.com')
      expect(customer_account.email).to eq('test2@example.com')
    end

    it 'updates multiple accounts with session' do
      customer_account_1 = pl.Customer.create(name: 'Brandy', email: 'test1@example.com')
      customer_account_2 = pl.Customer.create(name: 'Sandy', email: 'test2@example.com')

      updated_accounts = pl.update([
        [customer_account_1, { email: 'brandy@example.com' }],
        [customer_account_2, { email: 'sandy@example.com' }]
      ])

      expect(updated_accounts[0].email).to eq('brandy@example.com')
      expect(updated_accounts[1].email).to eq('sandy@example.com')
    end

    it 'gets customer with session' do
      customer_account = pl.Customer.create(name: 'Test', email: 'test@example.com')
      expect(pl.Customer.get(customer_account.id)).to be_truthy
    end

    it 'selects customer attributes with session' do
      customer_account = pl.Customer.create(name: 'Test', email: 'test@example.com')
      selected = pl.query(Payload::Customer).select('id').get(customer_account.id)
      expect(selected['id']).to eq(customer_account.id)
    end
  end
end

