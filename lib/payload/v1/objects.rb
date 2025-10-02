module Payload
  module V1
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
  end
end