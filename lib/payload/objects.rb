require "payload/arm/object"

module Payload
	class AccessToken < ARMObject
		@spec = { 'object' => 'account' }
	end

	class ClientToken < ARMObject
		@spec = { 'object' => 'access_token' }
		@poly = { 'type' => 'client' }
	end

	class OAuthToken < ARMObject
		@spec = { 'object' => 'oauth_token', 'endpoint' => '/oauth/token' }
	end

	class Account < ARMObject
		@spec = { 'object' => 'account' }
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

	class PaymentActivation < ARMObject
		@spec = { 'object' => 'payment_activation' }
	end

	class Webhook < ARMObject
		@spec = { 'object' => 'webhook' }
	end

	class PaymentLink < ARMObject
		@spec = { 'object' => 'payment_link' }
	end

	# V1 objects
	class LineItem < ARMObject
		@spec = { 'object' => 'line_item' }
	end

	class ChargeItem < ARMObject
		@spec = { 'object' => 'line_item' }
		@poly = { 'entry_type' => 'charge' }
	end

	class PaymentItem < ARMObject
		@spec = { 'object' => 'line_item' }
		@poly = { 'entry_type' => 'payment' }
	end

	class Customer < ARMObject
		@spec = { 'object' => 'customer' }
	end

	class ProcessingAccount < ARMObject
		@spec = { 'object' => 'processing_account' }
	end
	
	class Org < ARMObject
		@spec = { 'object' => 'org', 'endpoint' => '/account/orgs' }
	end

	# V2 objects
	class InvoiceItem < ARMObject
		@spec = { 'object' => 'invoice_item' }
	end

	class PaymentAllocation < ARMObject
		@spec = { 'object' => 'payment_allocation' }
	end

	class Profile < ARMObject
		@spec = { 'object' => 'profile' }
	end

	class BillingItem < ARMObject
		@spec = { 'object' => 'billing_item' }
	end

	class Intent < ARMObject
		@spec = { 'object' => 'intent' }
	end

	class Entity < ARMObject
		@spec = { 'object' => 'entity' }
	end

	class Stakeholder < ARMObject
		@spec = { 'object' => 'stakeholder' }
	end

	class ProcessingAgreement < ARMObject
		@spec = { 'object' => 'processing_agreement' }
	end

	class Transfer < ARMObject
		@spec = { 'object' => 'transfer' }
	end

	class TransactionOperation < ARMObject
		@spec = { 'object' => 'transaction_operation' }
	end

	class CheckFront < ARMObject
		@spec = { 'object' => 'check_front' }
	end

	class CheckBack < ARMObject
		@spec = { 'object' => 'check_back' }
	end

	class ProcessingRule < ARMObject
		@spec = { 'object' => 'processing_rule' }
	end

end
