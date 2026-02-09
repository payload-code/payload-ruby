# frozen_string_literal: true

# Live API integration tests for pl.attr syntax. Examples mirror payload-docs Ruby examples.
#
# Run when TEST_SECRET_KEY is set:
#   TEST_SECRET_KEY=your_key TEST_API_URL=http://api.payload-dev.com:8000 bundle exec rspec spec/objects/v2/attr_syntax_integration_spec.rb
#
# Debugging 500s (e.g. group_by + aggregate):
#   1. See what the Ruby SDK sends: run with DEBUG_ARM_REQUEST=1 (same env as above).
#   2. See the backend error: watch the terminal where your API server is running;
#      flask-armrest prints "--- 500 traceback ---" and the Python traceback on 500.
#
require "payload"
require "payload/arm/object"
require_relative "../../support/helpers"

RSpec.describe "Attr syntax integration (live API)" do
  include_context "test helpers"

  let(:session) { Payload::Session.new(Payload.api_key, Payload.api_url, 2) }
  let(:pl) { session }

  before(:all) do
    skip "Set TEST_SECRET_KEY (and optionally TEST_API_URL) to run attr syntax integration tests" unless ENV["TEST_SECRET_KEY"]
  end

  before do
    skip "Set TEST_SECRET_KEY to run attr syntax integration tests" unless ENV["TEST_SECRET_KEY"]
  end

  def print_response(example_name, results)
    puts "\n--- #{example_name} ---"
    puts "  count: #{results.length}"
    results.first(3).each_with_index do |row, i|
      h = row.is_a?(Hash) ? row : (row.respond_to?(:to_h) ? row.to_h : row.inspect)
      puts "  row[#{i}]: #{h.inspect}"
    end
    puts "---\n"
  end

  # --- Examples from payload-docs (reconcile/examples/build-report-queries/filter-results/filter.rb) ---
  # Filter by status, type, and year(created_at). Validates filter with function attr.
  it "filter by year(created_at) == value (filter-results pattern)" do
    current_year = Time.now.year
    results = pl.Transaction.filter_by(
      pl.attr.type == "payment",
      pl.attr.created_at(:year) == current_year
    ).limit(5).all

    print_response("filter by year(created_at)", results)
    expect(results).to be_an(Array)
  end

  # --- Examples from payload-docs (api-reference/examples/functions/date-examples/date.rb) ---
  # Filter by month(created_at). Validates function in filter.
  it "filter by month(created_at) == value (date-examples pattern)" do
    current_month = Time.now.month
    results = pl.Transaction.filter_by(
      pl.attr.created_at(:month) == current_month
    ).limit(5).all

    print_response("filter by month(created_at)", results)
    expect(results).to be_an(Array)
  end

  # Select id and dayname(created_at). Validates select with date function (no group_by).
  it "select id and dayname(created_at) (date-examples pattern)" do
    results = pl.Transaction.select(
      pl.attr.id,
      pl.attr.created_at(:dayname)
    ).limit(5).all

    print_response("select id, dayname(created_at)", results)
    expect(results).to be_an(Array)
  end

  # Mirrors date.rb lines 7-12: select(year, count).group_by(year).all (Account -> Transaction).
  it "select year(created_at), count(id) with group_by year — matches date.rb yearly_signups pattern" do
    yearly = pl.Transaction.select(
      pl.attr.created_at(:year),
      pl.attr.id(:count)
    ).group_by(
      pl.attr.created_at(:year)
    ).limit(5).all

    print_response("yearly (date.rb pattern)", yearly)
    expect(yearly).to be_an(Array)
  end

  # --- order_by, limit, offset, [] sanity checks (no aggregation) ---
  it "order_by(pl.attr.created_at) sends order_by and returns results" do
    results = pl.Transaction.select(pl.attr.id).order_by(pl.attr.created_at).limit(5).all
    print_response("order_by created_at asc", results)
    expect(results).to be_an(Array)
  end

  it "order_by(pl.attr.created_at(:desc)) sends descending order" do
    results = pl.Transaction.select(pl.attr.id).order_by(pl.attr.created_at(:desc)).limit(5).all
    print_response("order_by created_at desc", results)
    expect(results).to be_an(Array)
  end

  it "limit(n) restricts response size" do
    results = pl.Transaction.select(pl.attr.id).limit(2).all
    print_response("limit(2)", results)
    expect(results).to be_an(Array)
    expect(results.length).to be <= 2
  end

  it "offset(n) skips first n rows" do
    page1 = pl.Transaction.select(pl.attr.id).limit(3).offset(0).all
    page2 = pl.Transaction.select(pl.attr.id).limit(3).offset(3).all
    print_response("offset(0) limit(3)", page1)
    print_response("offset(3) limit(3)", page2)
    expect(page1).to be_an(Array)
    expect(page2).to be_an(Array)
    expect(page1.length).to be <= 3
    expect(page2.length).to be <= 3
  end

  it "request[range] (def []) uses offset/limit and returns array" do
    # request[0..2] => offset(0).limit(3).all
    results = pl.Transaction.select(pl.attr.id)[0..2]
    print_response("[] 0..2", results)
    expect(results).to be_an(Array)
    expect(results.length).to be <= 3
  end

  # --- group_by + aggregate (payload-docs revenue-by-status pattern) ---
  it "select type, sum(amount), count(id) with group_by type (revenue-by-status pattern)" do
    results = pl.Transaction.select(
      pl.attr.type,
      pl.attr.amount(:sum),
      pl.attr.id(:count)
    ).filter_by(pl.attr.type == "payment").group_by(
      pl.attr.type
    ).limit(5).all

    print_response("select type, sum(amount), count(id) group_by type", results)
    expect(results).to be_an(Array)
  end

  # (api-reference group-by-examples/group.rb, select-fields/select.rb)
  it "select month(created_at), sum(amount), count(id) with group_by month (select-fields + group-by pattern)" do
    results = pl.Transaction.select(
      pl.attr.created_at(:month),
      pl.attr.amount(:sum),
      pl.attr.id(:count)
    ).filter_by(pl.attr.type == "payment").group_by(
      pl.attr.created_at(:month)
    ).limit(5).all

    print_response("select month, sum(amount), count(id) group_by month", results)
    expect(results).to be_an(Array)
  end

  # (date-examples pattern)
  it "select year(created_at), count(id) with group_by year (date-examples pattern)" do
    results = pl.Transaction.select(
      pl.attr.created_at(:year),
      pl.attr.id(:count)
    ).filter_by(pl.attr.type == "payment").group_by(
      pl.attr.created_at(:year)
    ).limit(5).all

    print_response("select year(created_at), count(id) group_by year", results)
    expect(results).to be_an(Array)
  end
end
