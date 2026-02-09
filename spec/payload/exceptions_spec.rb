# frozen_string_literal: true

require "payload"

RSpec.describe Payload::TransactionDeclined do
  def api_error_payload(message:, details: nil)
    {
      "object" => "error",
      "error_type" => "TransactionDeclined",
      "error_description" => message,
      "details" => details,
    }.compact
  end

  it "inherits from BadRequest (HTTP 400)" do
    expect(described_class.superclass).to eq(Payload::BadRequest)
    expect(Payload::BadRequest.code).to eq("400")
  end

  it "sets message from first argument (same as request.rb: data['error_description'])" do
    e = described_class.new("Card declined", nil)
    expect(e.message).to eq("Card declined")
  end

  it "exposes #transaction as nil when data is nil" do
    e = described_class.new("Declined", nil)
    expect(e.transaction).to be_nil
  end

  it "exposes #transaction as nil when details is missing" do
    e = described_class.new("Declined", api_error_payload(message: "Declined"))
    expect(e.transaction).to be_nil
  end

  it "exposes #transaction as nil when details is not a Hash" do
    e = described_class.new("Declined", api_error_payload(message: "Declined", details: "string"))
    expect(e.transaction).to be_nil
  end

  it "builds a transaction object from data['details'] when present (API-realistic payload)" do
    details = {
      "id" => "txn_123",
      "object" => "transaction",
      "type" => "payment",
      "status" => "declined",
      "status_code" => "do_not_honor",
      "amount" => 100.0,
    }
    data = api_error_payload(message: "Transaction was declined", details: details)
    e = described_class.new(data["error_description"], data)

    expect(e.transaction).to be_a(Payload::ARMObject)
    expect(e.transaction.id).to eq("txn_123")
    expect(e.transaction["status"]).to eq("declined")
    expect(e.transaction["status_code"]).to eq("do_not_honor")
    expect(e.transaction["amount"]).to eq(100.0)
    expect(e.transaction).to be_a(Payload::Payment)
  end

  it "uses Transaction when get_cls returns nil for details (minimal details, no object key)" do
    details = { "id" => "txn_456", "status" => "declined" }
    data = api_error_payload(message: "Declined", details: details)
    e = described_class.new(data["error_description"], data)

    expect(e.transaction).to be_a(Payload::Transaction)
    expect(e.transaction.id).to eq("txn_456")
  end

  it "matches how ARM request raises: message from error_description, data = full response" do
    data = {
      "object" => "error",
      "error_type" => "TransactionDeclined",
      "error_description" => "There was an issue processing the payment",
      "details" => { "id" => "txn_789", "object" => "transaction", "status" => "declined" },
    }
    e = described_class.new(data["error_description"], data)

    expect(e.message).to eq("There was an issue processing the payment")
    expect(e.transaction).to be_a(Payload::ARMObject)
    expect(e.transaction.id).to eq("txn_789")
  end
end
