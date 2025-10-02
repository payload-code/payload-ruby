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
end
