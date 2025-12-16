require 'payload'
require 'payload/arm/object'
require_relative '../../support/helpers'

RSpec.describe 'Billing Integration Tests - V1' do
  include_context 'test helpers'

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 1) }
  let(:h) { V1Helpers.new(session) }

  describe 'Billing Schedule' do
    let(:billing_schedule) do
      proc_account = h.create_processing_account
      customer_account = h.create_customer_account
      session.BillingSchedule.create(
        start_date: '2019-01-01',
        end_date: '2019-12-31',
        recurring_frequency: 'monthly',
        type: 'subscription',
        customer_id: customer_account.id,
        processing_id: proc_account.id,
        charges: [
          {
            type: 'option_1',
            amount: 39.99
          }
        ]
      )
    end

    it 'creates a billing schedule' do
      schedule = billing_schedule
      expect(schedule.charges[0]['amount']).to eq(39.99)
    end

    it 'updates billing schedule frequency' do
      schedule = billing_schedule
      expect(schedule.charges[0]['amount']).to eq(39.99)

      schedule.update(recurring_frequency: 'quarterly')
      expect(schedule.recurring_frequency).to eq('quarterly')
    end

    it 'deletes a billing schedule' do
      schedule = billing_schedule
      schedule.delete
      
      expect {
        session.BillingSchedule.get(schedule.id)
      }.to raise_error(Payload::NotFound)
    end
  end
end

