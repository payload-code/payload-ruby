# frozen_string_literal: true

# Specs for Attr DSL, AttrRoot, Attr, and ARMFilter (comparisons, | for OR).
require "payload"
require "payload/arm/attr"

RSpec.describe Payload::AttrRoot do
  let(:root) { described_class.new }

  describe "attribute access" do
    it "returns an Attr for any method name" do
      expect(root.id).to be_a(Payload::Attr)
      expect(root.id.to_s).to eq("id")
      expect(root.created_at).to be_a(Payload::Attr)
      expect(root.created_at.to_s).to eq("created_at")
    end

    it "returns an Attr for chained access (exact string form depends on function vs property handling)" do
      chained = root.sender.account_id
      expect(chained).to be_a(Payload::Attr)
      expect(chained.to_s).to match(/\Asender.*account_id\z|account_id\(sender\)\z/)
    end
  end
end

RSpec.describe Payload::Attr do
  describe "simple attribute" do
    it "has key and to_s as the param when no parent" do
      attr = Payload::Attr.new("amount")
      expect(attr.key).to eq("amount")
      expect(attr.to_s).to eq("amount")
    end
  end

  describe "nested attribute" do
    it "builds key and to_s as parent[param]" do
      parent = Payload::Attr.new("totals")
      attr = Payload::Attr.new("total", parent)
      expect(attr.key).to eq("totals[total]")
      expect(attr.to_s).to eq("totals[total]")
    end
  end

  describe "function form (after .call)" do
    it "serializes as name(parent_key) when marked as method" do
      parent = Payload::Attr.new("created_at")
      attr = Payload::Attr.new("month", parent)
      attr.call
      expect(attr.to_s).to eq("month(created_at)")
    end

    it "serializes nested path in function form" do
      parent = Payload::Attr.new("total", Payload::Attr.new("totals"))
      attr = Payload::Attr.new("sum", parent)
      attr.call
      expect(attr.to_s).to eq("sum(totals[total])")
    end

    it "raises when chaining after a method" do
      parent = Payload::Attr.new("created_at")
      attr = Payload::Attr.new("month", parent)
      attr.call
      expect { attr.day }.to raise_error(RuntimeError, /cannot get attr of method/)
    end
  end

  describe "comparisons (return ARMFilter subclasses)" do
    let(:attr_amount) { Payload::Attr.new("amount") }
    let(:attr_status) { Payload::Attr.new("status") }

    it "== returns ARMEqual with correct attr and opval" do
      f = attr_status == "processed"
      expect(f).to be_a(Payload::ARMEqual)
      expect(f.attr).to eq("status")
      expect(f.opval).to eq("processed")
    end

    it "!= returns ARMNotEqual with ! prefix" do
      f = attr_status != "draft"
      expect(f).to be_a(Payload::ARMNotEqual)
      expect(f.attr).to eq("status")
      expect(f.opval).to eq("!draft")
    end

    it "> returns ARMGreaterThan" do
      f = attr_amount > 100
      expect(f).to be_a(Payload::ARMGreaterThan)
      expect(f.attr).to eq("amount")
      expect(f.opval).to eq(">100")
    end

    it "< returns ARMLessThan" do
      f = attr_amount < 500
      expect(f).to be_a(Payload::ARMLessThan)
      expect(f.opval).to eq("<500")
    end

    it ">= returns ARMGreaterThanEqual" do
      f = attr_amount >= 100
      expect(f).to be_a(Payload::ARMGreaterThanEqual)
      expect(f.opval).to eq(">=100")
    end

    it "<= returns ARMLessThanEqual" do
      f = attr_amount <= 100
      expect(f).to be_a(Payload::ARMLessThanEqual)
      expect(f.opval).to eq("<=100")
    end

    it "contains returns ARMContains with ?* op" do
      attr = Payload::Attr.new("description")
      f = attr.contains("INV -")
      expect(f).to be_a(Payload::ARMContains)
      expect(f.attr).to eq("description")
      expect(f.opval).to eq("?*INV -")
    end

    it "comparisons use Attr key for nested paths" do
      nested = Payload::Attr.new("total", Payload::Attr.new("totals"))
      f = nested > 0
      expect(f.attr).to eq("totals[total]")
      expect(f.opval).to eq(">0")
    end
  end

  describe "Attr class-level (Payload::Attr.name)" do
    it "returns Attr via method_missing" do
      expect(Payload::Attr.created_at).to be_a(Payload::Attr)
      expect(Payload::Attr.created_at.to_s).to eq("created_at")
    end
  end
end

RSpec.describe Payload::ARMFilter do
  describe "#| (OR)" do
    it "combines two filters on the same attribute and returns ARMEqual with joined opval" do
      left = Payload::ARMGreaterThan.new(Payload::Attr.amount, 100)
      right = Payload::ARMLessThan.new(Payload::Attr.amount, 50)
      combined = left | right
      expect(combined).to be_a(Payload::ARMEqual)
      expect(combined.attr).to eq("amount")
      expect(combined.opval).to eq(">100|<50")
    end

    it "raises TypeError when other is not an ARMFilter" do
      f = Payload::ARMEqual.new(Payload::Attr.status, "active")
      expect { f | "invalid" }.to raise_error(TypeError, /invalid type/)
    end

    it "raises ArgumentError when attributes differ" do
      f1 = Payload::ARMEqual.new(Payload::Attr.status, "active")
      f2 = Payload::ARMEqual.new(Payload::Attr.type, "payment")
      expect { f1 | f2 }.to raise_error(ArgumentError, /only works on the same attribute/)
    end
  end

  describe "filter subclasses op values" do
    it "ARMEqual has empty op" do
      f = Payload::ARMEqual.new("status", "active")
      expect(f.opval).to eq("active")
    end

    it "ARMNotEqual has ! prefix" do
      f = Payload::ARMNotEqual.new("status", "draft")
      expect(f.opval).to eq("!draft")
    end

    it "ARMGreaterThan has > prefix" do
      f = Payload::ARMGreaterThan.new("amount", 100)
      expect(f.opval).to eq(">100")
    end

    it "ARMLessThan has < prefix" do
      f = Payload::ARMLessThan.new("amount", 200)
      expect(f.opval).to eq("<200")
    end

    it "ARMContains has ?* prefix" do
      f = Payload::ARMContains.new("email", "example.com")
      expect(f.opval).to eq("?*example.com")
    end
  end
end
