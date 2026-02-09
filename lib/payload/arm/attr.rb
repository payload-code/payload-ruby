# frozen_string_literal: true

module Payload
  class ARMFilter
    attr_reader :attr, :opval, :val

    def initialize(attr, val)
      @attr = attr.to_s
      @val = val
      @opval = self.class.op + val.to_s
    end

    def self.op
      ''
    end

    def |(other)
      raise TypeError, 'invalid type' unless other.is_a?(Payload::ARMFilter)
      raise ArgumentError, '`or` only works on the same attribute' if other.attr != @attr
      joined = [@opval, other.opval].join('|')
      Payload::ARMEqual.new(@attr, joined)
    end
  end

  class ARMEqual < ARMFilter
    def self.op
      ''
    end
  end

  class ARMNotEqual < ARMFilter
    def self.op
      '!'
    end
  end

  class ARMGreaterThan < ARMFilter
    def self.op
      '>'
    end
  end

  class ARMLessThan < ARMFilter
    def self.op
      '<'
    end
  end

  class ARMGreaterThanEqual < ARMFilter
    def self.op
      '>='
    end
  end

  class ARMLessThanEqual < ARMFilter
    def self.op
      '<='
    end
  end

  class ARMContains < ARMFilter
    def self.op
      '?*'
    end
  end

  # Root proxy for pl.attr so that pl.attr.name returns an Attr (not Class#name).
  # Session#attr returns this instead of the Attr class to avoid Class/Module methods (e.g. .name) shadowing attribute names.
  class AttrRoot
    def method_missing(name, *args)
      if args.size == 1 && args[0].is_a?(Symbol)
        inner = Attr.new(name.to_s)
        Attr.new(args[0].to_s, inner).call
      else
        Attr.new(name.to_s)
      end
    end

    def respond_to_missing?(name, include_private = false)
      true
    end
  end

  # Attribute DSL for select/group_by/order_by and filter expressions.
  # - pl.attr.id -> "id"
  # - pl.attr.created_at(:month) -> "month(created_at)"
  # - pl.attr.amount(:sum) -> "sum(amount)"
  # - pl.attr.sender.account_id -> "sender[account_id]"
  class Attr
    attr_reader :param, :parent

    class << self
      def method_missing(name, *args)
        new(name.to_s)
      end

      def respond_to_missing?(name, include_private = false)
        true
      end
    end

    def initialize(param, parent = nil)
      @param = param.to_s
      @parent = parent
      @is_method = false
    end

    def key
      @parent ? "#{@parent.key}[#{@param}]" : @param
    end

    def to_s
      @is_method ? "#{@param}(#{@parent.key})" : key
    end

    def method_missing(name, *args)
      raise "cannot get attr of method" if @is_method

      if args.size == 1 && args[0].is_a?(Symbol)
        inner = Attr.new(name.to_s, self)
        Attr.new(args[0].to_s, inner).call
      else
        Attr.new(name.to_s, self)
      end
    end

    def respond_to_missing?(name, include_private = false)
      true
    end

    # Mark attribute as a function call (e.g. .month(), .sum())
    def call
      @is_method = true
      self
    end

    def ==(other)
      ARMEqual.new(self, other)
    end

    def !=(other)
      ARMNotEqual.new(self, other)
    end

    def >(other)
      ARMGreaterThan.new(self, other)
    end

    def <(other)
      ARMLessThan.new(self, other)
    end

    def >=(other)
      ARMGreaterThanEqual.new(self, other)
    end

    def <=(other)
      ARMLessThanEqual.new(self, other)
    end

    def contains(other)
      ARMContains.new(self, other)
    end
  end
end
