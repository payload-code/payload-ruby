# frozen_string_literal: true

# Specs for ARM request query features: group_by, order_by, limit, offset, slice, pl.attr filters.
require "payload"
require "payload/arm/object"

RSpec.describe Payload::ARMRequest do
  describe "#group_by" do
    let(:instance) { described_class.new(Payload::Invoice, nil) }

    it "appends to group_by and returns self" do
      result = instance.group_by(Payload::Attr.created_at.year(), Payload::Attr.status)
      expect(result).to be(instance)
      expect(instance.instance_variable_get(:@group_by).map(&:to_s)).to eq(["year(created_at)", "status"])
    end

    it "includes group_by in request params when all() is called" do
      Payload::api_key = "test_key"
      instance.instance_variable_set(:@cls, Payload::Invoice)

      expect(instance).to receive(:_execute_request) do |_http, request|
        query = request.path.split("?")[1]
        expect(query).to include("group_by%5B0%5D=") # group_by[0]=
        expect(query).to include("group_by%5B1%5D=") # group_by[1]=
        QuerySpecMockResponse.new('{"object":"list","values":[]}')
      end

      instance.group_by("year(created_at)", "status").all()
    end
  end

  describe "#order_by" do
    let(:instance) { described_class.new(Payload::Account, nil) }

    it "appends to order_by and returns self" do
      result = instance.order_by("created_at", "desc(id)")
      expect(result).to be(instance)
      expect(instance.instance_variable_get(:@order_by)).to eq(["created_at", "desc(id)"])
    end

    it "includes order_by in request params when all() is called" do
      Payload::api_key = "test_key"
      instance.instance_variable_set(:@cls, Payload::Account)

      expect(instance).to receive(:_execute_request) do |_http, request|
        query = request.path.split("?")[1]
        expect(query).to include("order_by%5B0%5D=created_at")
        expect(query).to include("order_by%5B1%5D=desc%28id%29")
        QuerySpecMockResponse.new('{"object":"list","values":[]}')
      end

      instance.order_by("created_at", "desc(id)").all()
    end
  end

  describe "#limit and #offset" do
    let(:instance) { described_class.new(Payload::Account, nil) }

    it "sets limit and offset and returns self" do
      result = instance.limit(10).offset(20)
      expect(result).to be(instance)
      expect(instance.instance_variable_get(:@limit)).to eq(10)
      expect(instance.instance_variable_get(:@offset)).to eq(20)
    end

    it "includes limit and offset in request params when all() is called" do
      Payload::api_key = "test_key"
      instance.instance_variable_set(:@cls, Payload::Account)

      expect(instance).to receive(:_execute_request) do |_http, request|
        query = request.path.split("?")[1]
        expect(query).to include("limit=10")
        expect(query).to include("offset=20")
        QuerySpecMockResponse.new('{"object":"list","values":[]}')
      end

      instance.limit(10).offset(20).all()
    end
  end

  describe "#request_params" do
    it "merges filters, filter_objects, group_by, order_by, limit, offset into query params" do
      instance = described_class.new(Payload::Transaction, nil)
      instance.instance_variable_set(:@filters, { "fields" => "id,amount" })
      instance.instance_variable_set(:@group_by, ["status"])
      instance.instance_variable_set(:@order_by, ["desc(created_at)"])
      instance.instance_variable_set(:@limit, 5)
      instance.instance_variable_set(:@offset, 10)

      filter_obj = Payload::ARMGreaterThan.new(Payload::Attr.amount, 100)
      instance.instance_variable_set(:@filter_objects, [filter_obj])

      params = instance.request_params

      expect(params["fields"]).to eq("id,amount")
      expect(params["group_by[0]"]).to eq("status")
      expect(params["order_by[0]"]).to eq("desc(created_at)")
      expect(params["limit"]).to eq("5")
      expect(params["offset"]).to eq("10")
      expect(params[filter_obj.attr]).to eq(filter_obj.opval)
    end
  end

  describe "#[] (slice)" do
    let(:instance) { described_class.new(Payload::Account, nil) }

    it "raises TypeError for non-Range key" do
      expect { instance["foo"] }.to raise_error(TypeError, /invalid key or index/)
      expect { instance[5] }.to raise_error(TypeError, /invalid key or index/)
    end

    it "raises ArgumentError for negative begin" do
      expect { instance[-1..10] }.to raise_error(ArgumentError, /Negative slice indices not supported/)
    end

    it "raises ArgumentError for negative end" do
      expect { instance[0..-5] }.to raise_error(ArgumentError, /Negative slice indices not supported/)
    end

    it "calls offset(begin).limit(size).all() for a range and returns result" do
      Payload::api_key = "test_key"
      instance.instance_variable_set(:@cls, Payload::Account)

      expect(instance).to receive(:_execute_request) do |_http, request|
        query = request.path.split("?")[1]
        expect(query).to include("offset=10")
        expect(query).to include("limit=10")
        QuerySpecMockResponse.new('{"object":"list","values":[{"id":"acct_1","object":"customer"}]}')
      end

      result = instance[10..19]
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result[0].id).to eq("acct_1")
    end
  end

  describe "#filter_by with pl.attr filter objects" do
    it "extracts ARM filter objects and merges their attr/opval into request params" do
      session = Payload::Session.new("test_key", "https://api.test.com", "v2")
      instance = described_class.new(Payload::Transaction, session)
      pl = session
      filter_expr = (pl.attr.amount > 100) | (pl.attr.amount < 200)

      instance.filter_by(filter_expr)

      expect(instance.instance_variable_get(:@filter_objects)).to include(be_a(Payload::ARMFilter))
      params = instance.request_params
      expect(params.keys).to include(filter_expr.attr)
      expect(params[filter_expr.attr]).to eq(filter_expr.opval)
    end

    it "builds GET request with filter object serialized in query string" do
      Payload::api_key = "test_key"
      session = Payload::Session.new("test_key", "https://api.test.com", "v2")
      instance = described_class.new(Payload::Transaction, session)
      filter_expr = session.attr.amount > 100

      instance.filter_by(filter_expr)

      expect(instance).to receive(:_execute_request) do |_http, request|
        query = request.path.split("?")[1]
        expect(query).to include("amount=")
        expect(query).to include("%3E100") # URL-encoded ">100"
        QuerySpecMockResponse.new('{"object":"list","values":[]}')
      end

      instance.all()
    end
  end

  describe "#filter_by with multiple filters" do
    it "accumulates multiple filter objects and merges keyword filters into @filters" do
      instance = described_class.new(Payload::Invoice, nil)
      f1 = Payload::ARMEqual.new(Payload::Attr.status, "open")
      f2 = Payload::ARMGreaterThan.new(Payload::Attr.amount, 50)

      instance.filter_by(f1).filter_by(f2).filter_by(custom_key: "value")

      fo = instance.instance_variable_get(:@filter_objects)
      expect(fo).to include(f1, f2)
      params = instance.request_params
      expect(params["status"]).to eq("open")
      expect(params["amount"]).to eq(">50")
      expect(instance.instance_variable_get(:@filters)[:custom_key]).to eq("value")
    end
  end
end

# Local mock to avoid conflicting with MockResponse in other specs (e.g. payment_spec).
class QuerySpecMockResponse
  def initialize(body = '{"object":"list","values":[]}')
    @body = body
  end

  def code
    "200"
  end

  def body
    @body
  end
end
