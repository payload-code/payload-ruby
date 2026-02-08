# frozen_string_literal: true

require "payload"

RSpec.describe Payload::TransactionDeclined do
  it "inherits from BadRequest" do
    expect(described_class.superclass).to eq(Payload::BadRequest)
  end

  it "sets message from first argument" do
    e = described_class.new("Card declined", nil)
    expect(e.message).to eq("Card declined")
  end

  it "exposes #transaction as nil when data has no details" do
    e = described_class.new("Declined", nil)
    expect(e.transaction).to be_nil
  end

  it "exposes #transaction as nil when details is not a Hash" do
    e = described_class.new("Declined", "details" => "string")
    expect(e.transaction).to be_nil
  end

  it "builds a Transaction instance from data['details'] when present" do
    details = { "id" => "txn_123", "object" => "transaction", "status" => { "code" => "declined" } }
    e = described_class.new("Declined", "error_type" => "TransactionDeclined", "details" => details)

    expect(e.transaction).to be_a(Payload::Transaction)
    expect(e.transaction.id).to eq("txn_123")
    expect(e.transaction["status"]).to eq({ "code" => "declined" })
  end

  it "uses Transaction when get_cls returns nil for details" do
    details = { "id" => "txn_456" }
    e = described_class.new("Declined", "details" => details)

    expect(e.transaction).to be_a(Payload::Transaction)
    expect(e.transaction.id).to eq("txn_456")
  end
end
