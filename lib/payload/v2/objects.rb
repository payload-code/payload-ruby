module Payload
  module V2
    class InvoiceItem < ARMObject
      @spec = { 'object' => 'invoice_item' }
    end

    class LineItem < ARMObject
      @spec = { 'object' => 'invoice_item' }
      @poly = { 'type' => 'line_item' }
    end
  
    class ChargeItem < ARMObject
      @spec = { 'object' => 'invoice_item' }
      @poly = { 'type' => 'line_item' }
    end
  
    class PaymentItem < ARMObject
      @spec = { 'object' => 'payment_allocation' }
    end

    class Customer < ARMObject
      @spec = { 'object' => 'account' }
      @poly = { 'type' => 'customer' }
    end

    class ProcessingAccount < ARMObject
      @spec = { 'object' => 'account' }
      @poly = { 'type' => 'processing' }
    end

    class Org < ARMObject
      @spec = { 'object' => 'profile' }
    end

    class Profile < ARMObject
      @spec = { 'object' => 'profile' }
    end
  end
end