# frozen_string_literal: true

require "payload"
require "payload/arm/object"

RSpec.describe Payload::ARMObject do
  describe "method_missing (attribute access)" do
    let(:session) { Payload::Session.new("test_key", "https://api.test.com", "v2") }

    it "returns value for present key" do
      obj = Payload::Invoice.new({ "id" => "inv_1", "amount" => 100 }, session)
      expect(obj.id).to eq("inv_1")
      expect(obj.amount).to eq(100)
    end

    it "raises NoMethodError for missing key (strict behavior preserved)" do
      obj = Payload::Invoice.new({ "id" => "inv_1" }, session)
      expect { obj.nonexistent_key }.to raise_error(NoMethodError, /nonexistent_key/)
      expect { obj.amount }.to raise_error(NoMethodError, /amount/)
    end

    it "strips trailing = for setter-like names and returns value" do
      obj = Payload::Account.new({ "name" => "Acme" }, session)
      expect(obj.name).to eq("Acme")
    end
  end

  describe "#json" do
    let(:session) { Payload::Session.new("test_key", "https://api.test.com", "v2") }

    it "returns same as to_json" do
      obj = Payload::Invoice.new({ "id" => "inv_1", "object" => "invoice" }, session)
      expect(obj.json).to eq(obj.to_json)
      expect(obj.json).to include("inv_1")
      expect(obj.json).to include("invoice")
    end
  end

  describe ".order_by, .limit, .offset with session" do
    it "delegates to ARMRequest with session and returns chainable request" do
      session = Payload::Session.new("test_key", "https://api.test.com", "v2")

      req = Payload::Invoice.order_by("created_at", session: session)
      expect(req).to be_a(Payload::ARMRequest)
      expect(req.instance_variable_get(:@order_by)).to include("created_at")
      expect(req.instance_variable_get(:@session)).to eq(session)

      req = Payload::Invoice.limit(10, session: session)
      expect(req.instance_variable_get(:@limit)).to eq(10)

      req = Payload::Invoice.offset(20, session: session)
      expect(req.instance_variable_get(:@offset)).to eq(20)
    end
  end

  describe ".select with session" do
    it "passes session to _get_request so request uses session" do
      session = Payload::Session.new("test_key", "https://api.test.com", "v2")

      req = Payload::Invoice.select("id", "amount", session: session)
      expect(req).to be_a(Payload::ARMRequest)
      expect(req.instance_variable_get(:@session)).to eq(session)
      expect(req.instance_variable_get(:@filters)["fields"]).to eq("id,amount")
    end
  end

  describe "#[] (bracket access)" do
    let(:session) { Payload::Session.new("test_key", "https://api.test.com", "v2") }

    it "returns value for string key" do
      obj = Payload::Invoice.new({ "id" => "inv_1", "status" => "open" }, session)
      expect(obj["id"]).to eq("inv_1")
      expect(obj["status"]).to eq("open")
    end

    it "returns value for symbol key (data keys are stored as strings)" do
      obj = Payload::Invoice.new({ "id" => "inv_1" }, session)
      expect(obj[:id]).to eq("inv_1")
    end

    it "returns nil for missing key" do
      obj = Payload::Invoice.new({ "id" => "inv_1" }, session)
      expect(obj["missing"]).to be_nil
    end
  end

  describe "#to_json" do
    let(:session) { Payload::Session.new("test_key", "https://api.test.com", "v2") }

    it "includes @data in JSON output" do
      obj = Payload::Invoice.new({ "id" => "inv_1", "object" => "invoice", "amount" => 99 }, session)
      json = obj.to_json
      expect(json).to include("inv_1")
      expect(json).to include("invoice")
      expect(json).to include("99")
    end

    it "merges class poly when present" do
      obj = Payload::Payment.new({ "id" => "txn_1", "object" => "transaction", "type" => "payment" }, session)
      json = obj.to_json
      expect(json).to include("payment")
      expect(json).to include("txn_1")
    end
  end

  describe "#respond_to_missing?" do
    let(:session) { Payload::Session.new("test_key", "https://api.test.com", "v2") }

    it "returns true for key present in data" do
      obj = Payload::Invoice.new({ "id" => "inv_1", "amount" => 100 }, session)
      expect(obj.respond_to?(:id)).to be true
      expect(obj.respond_to?(:amount)).to be true
    end

    it "returns false for key missing from data (so method_missing will call super)" do
      obj = Payload::Invoice.new({ "id" => "inv_1" }, session)
      expect(obj.respond_to?(:nonexistent_key)).to be false
    end
  end
end
