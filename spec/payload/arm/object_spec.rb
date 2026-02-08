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
end
