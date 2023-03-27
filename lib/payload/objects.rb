require "payload/arm/object"

module Payload
	class Account < ARMObject
		@spec = { 'object' => 'account' }
	end

	class Customer < ARMObject
		@spec = { 'object' => 'customer' }
	end

	class ProcessingAccount < ARMObject
		@spec = { 'object' => 'processing_account' }
	end

	class Org < ARMObject
		@spec = { 'object' => 'org', 'endoint' => '/account/orgs' }
	end

	class Transaction < ARMObject
		@spec = { 'object' => 'transaction' }
	end

	class Payment < ARMObject
		@spec = { 'object' => 'transaction' }
		@poly = { 'type' => 'payment' }
	end

	class Refund < ARMObject
		@spec = { 'object' => 'transaction' }
		@poly = { 'type' => 'refund' }
	end

	class Ledger < ARMObject
		@spec = { 'object' => 'transaction_ledger' }
	end

	class PaymentMethod < ARMObject
		@spec = { 'object' => 'payment_method' }
	end

	class Card < ARMObject
		@spec = { 'object' => 'payment_method' }
		@poly = { 'type' => 'card' }
	end

	class BankAccount < ARMObject
		@spec = { 'object' => 'payment_method' }
		@poly = { 'type' => 'bank_account' }
	end

	class BillingSchedule < ARMObject
		@spec = { 'object' => 'billing_schedule' }
	end

	class BillingCharge < ARMObject
		@spec = { 'object' => 'billing_charge' }
	end

	class Invoice < ARMObject
		@spec = { 'object' => 'invoice' }
	end

	class LineItem < ARMObject
		@spec = { 'object' => 'line_item' }
	end

	class ChargeItem < ARMObject
		@spec = { 'object' => 'line_item' }
		@poly = { 'type' => 'charge' }
	end

	class PaymentItem < ARMObject
		@spec = { 'object' => 'line_item' }
		@poly = { 'type' => 'payment' }
	end

	class PaymentActivation < ARMObject
		@spec = { 'object' => 'payment_activation' }
	end

	class Webhook < ARMObject
		@spec = { 'object' => 'webhook' }
	end
end
