# frozen_string_literal: true

module NPlusOneControl
  module Collectors
    class Base
      def bind pattern, &block
        ::ActiveSupport::Notifications.subscribe(self.class.topic) do |*args|
          query = parse_log pattern, *args
          yield(query) if query.present?
        end
      end

      def unbind
        ::ActiveSupport::Notifications.unsubscribe self.class.topic
      end

      def publish payload
        ::ActiveSupport::Notifications.instrument self.class.topic, payload
      end

      def self.topic
        raise "#{name} does not implement #topic"
      end

      private

      def extract_query_source_location(locations)
        NPlusOneControl.backtrace_cleaner.call(locations.lazy)
          .take(NPlusOneControl.backtrace_length).to_a
      end
    end
  end
end
