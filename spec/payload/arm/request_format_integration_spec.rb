# frozen_string_literal: true

require "payload"
require "payload/arm/object"
require_relative "../../support/helpers"

RSpec.describe "confirm request format is valid" do
  include_context "test helpers"

  [1, 2].each do |api_version|
    context "API v#{api_version}" do
      let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, api_version) }
      let(:pl) { session }

      context "date functions" do
        it "filter with year(attr) ==" do
          results = pl.Transaction.filter_by(
            pl.attr.type == "payment",
            pl.attr.created_at(:year) == Time.now.year
          ).limit(5).all
          expect(results).to be_an(Array)
        end

        it "filter with month(attr) ==" do
          results = pl.Transaction.filter_by(
            pl.attr.created_at(:month) == Time.now.month
          ).limit(5).all
          expect(results).to be_an(Array)
        end

        it "select with dayname(attr)" do
          results = pl.Transaction.select(
            pl.attr.id,
            pl.attr.created_at(:dayname)
          ).limit(5).all
          expect(results).to be_an(Array)
        end

        it "group_by year(attr) with count" do
          yearly = pl.Transaction.select(
            pl.attr.created_at(:year),
            pl.attr.id(:count)
          ).group_by(pl.attr.created_at(:year)).limit(5).all
          expect(yearly).to be_an(Array)
        end
      end

      context "order_by" do
        it "order_by ascending" do
          results = pl.Transaction.select(pl.attr.id).order_by(pl.attr.created_at).limit(5).all
          expect(results).to be_an(Array)
        end

        it "order_by descending" do
          results = pl.Transaction.select(pl.attr.id).order_by(pl.attr.created_at(:desc)).limit(5).all
          expect(results).to be_an(Array)
        end
      end

      context "limit, offset, and range" do
        it "limit" do
          results = pl.Transaction.select(pl.attr.id).limit(2).all
          expect(results).to be_an(Array)
          expect(results.length).to be <= 2
        end

        it "offset" do
          page1 = pl.Transaction.select(pl.attr.id).limit(3).offset(0).all
          page2 = pl.Transaction.select(pl.attr.id).limit(3).offset(3).all
          expect(page1).to be_an(Array)
          expect(page2).to be_an(Array)
          expect(page1.length).to be <= 3
          expect(page2.length).to be <= 3
        end

        it "range operator []" do
          results = pl.Transaction.select(pl.attr.id)[0..2]
          expect(results).to be_an(Array)
          expect(results.length).to be <= 3
        end
      end

      context "nested attr" do
        it "select with nested attr (sender.account_id)" do
          results = pl.Transaction.select(
            pl.attr.id,
            pl.attr.sender.account_id
          ).filter_by(pl.attr.type == "payment").limit(5).all
          expect(results).to be_an(Array)
        end
      end

      context "filter operators" do
        it "filter with >" do
          results = pl.Transaction.filter_by(
            pl.attr.type == "payment",
            pl.attr.amount > 0
          ).select(pl.attr.id, pl.attr.amount).limit(5).all
          expect(results).to be_an(Array)
        end

        it "filter with <" do
          results = pl.Transaction.filter_by(
            pl.attr.type == "payment",
            pl.attr.amount < 1_000_000
          ).select(pl.attr.id, pl.attr.amount).limit(5).all
          expect(results).to be_an(Array)
        end

        it "filter with !=" do
          results = pl.Transaction.filter_by(
            pl.attr.type != "nonexistent_type"
          ).select(pl.attr.id, pl.attr.type).limit(5).all
          expect(results).to be_an(Array)
        end

        it "filter with contains" do
          results = pl.Transaction.filter_by(
            pl.attr.type == "payment",
            pl.attr.description.contains("")
          ).select(pl.attr.id, pl.attr.description).limit(5).all
          expect(results).to be_an(Array)
        end
      end

      context "filter OR (chained conditions)" do
        it "filter with OR (|) on same attribute" do
          or_filter = (pl.attr.amount > 0) | (pl.attr.amount < 1_000_000)
          results = pl.Transaction.filter_by(
            pl.attr.type == "payment",
            or_filter
          ).select(pl.attr.id, pl.attr.amount).limit(5).all
          expect(results).to be_an(Array)
        end
      end

      context "group_by and aggregates" do
        it "group_by with sum and count" do
          results = pl.Transaction.select(
            pl.attr.type,
            pl.attr.amount(:sum),
            pl.attr.id(:count)
          ).filter_by(pl.attr.type == "payment").group_by(pl.attr.type).limit(5).all
          expect(results).to be_an(Array)
        end

        it "group_by month(attr) with sum and count" do
          results = pl.Transaction.select(
            pl.attr.created_at(:month),
            pl.attr.amount(:sum),
            pl.attr.id(:count)
          ).filter_by(pl.attr.type == "payment").group_by(pl.attr.created_at(:month)).limit(5).all
          expect(results).to be_an(Array)
        end

        it "group_by year(attr) with count" do
          results = pl.Transaction.select(
            pl.attr.created_at(:year),
            pl.attr.id(:count)
          ).filter_by(pl.attr.type == "payment").group_by(pl.attr.created_at(:year)).limit(5).all
          expect(results).to be_an(Array)
        end
      end
    end
  end
end
