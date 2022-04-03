# frozen_string_literal: true

require_relative './collector'

module NPlusOneControl
  # Runs code for every scale factor
  # and returns collected queries.
  class Executor
      class << self
      attr_accessor :transaction_begin
      attr_accessor :transaction_rollback
    end

    attr_reader :current_scale

    self.transaction_begin = -> do
      # TODO: Refactor to support adapter
      ::ActiveRecord::Base.connection.begin_transaction(joinable: false) if defined?(::ActiveRecord)
    end

    self.transaction_rollback = -> do
      # TODO: Refactor to support adapter
      ::ActiveRecord::Base.connection.rollback_transaction if defined?(::ActiveRecord)
    end

    def initialize(population: nil, scale_factors: nil, matching: nil)
      @population = population
      @scale_factors = scale_factors
      @matching = matching
    end

    # rubocop:disable Metrics/MethodLength
    def call
      raise ArgumentError, "Block is required!" unless block_given?

      results = []
      collector = ::NPlusOneControl::Collector.new(matching)

      (scale_factors || NPlusOneControl.default_scale_factors).each do |scale|
        @current_scale = scale
        with_transaction do
          population&.call(scale)
          results << [scale, collector.call { yield }]
        end
      end
      results
    end
    # rubocop:enable Metrics/MethodLength

    private

    def with_transaction
      transaction_begin.call
      yield
    ensure
      transaction_rollback.call
    end

    def transaction_begin
      self.class.transaction_begin
    end

    def transaction_rollback
      self.class.transaction_rollback
    end

    attr_reader :population, :scale_factors, :matching
  end
end
