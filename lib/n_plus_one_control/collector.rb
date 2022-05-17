# frozen_string_literal: true

require "n_plus_one_control/collectors/base"
require "n_plus_one_control/collectors/mongoid"
require "n_plus_one_control/collectors/active_record"

module NPlusOneControl
  class Collector
    # Subscribes to ActiveSupport notifications and collect matching queries.

    attr_reader :queries

    def initialize(pattern)
      @queries = []
      @pattern = pattern
    end

    class << self
      def adapters
        return @adapters unless @adapters.nil?

        @adapters = {}

        %w[ActiveRecord Mongoid].each do |k|
          klass = k.safe_constantize
          if klass.present?
            @adapters[k.underscore.to_sym] = "::NPlusOneControl::Collectors::#{k}".constantize.new
          end
        end

        @adapters
      end

      %i[active_record mongoid].each do |k|
        define_method :"#{k}?" do
          adapters[k].present?
        end

        define_method :"#{k}" do
          adapters[k]
        end
      end
    end

    def adapters
      self.class.adapters
    end

    def call
      @queries = []

      subscribed(@pattern) do |queries|
        yield
        @queries = queries
      end

      @queries
    end

    def subscribed pattern, &block
      events = []

      # Wrap around and subscribe to events between execution
      adapters.each do |k, adapter|
        adapter.bind(pattern) do |event|
          events << event
        end
      end

      yield(events)

      adapters.each do |k, adapter|
        adapter.unbind
      end
    end
  end
end
