# frozen_string_literal: true

module NPlusOneControl
  module Collectors
    class ActiveRecord < Base
      ACTIVE_RECORD_SQL_EVENT = "sql.active_record"
      PARSABLE_EVENT_NAME = %w[CACHE SCHEMA].freeze
      IGNORE_QUERY_MATCHES = /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/.freeze

      # Used to extract a table name from a query
      EXTRACT_TABLE_RXP = /(insert into|update|delete from|from) ['"`](\S+)['"`]/i.freeze

      # Used to convert a query part extracted by the regexp above to the corresponding
      # human-friendly type
      QUERY_PART_TO_TYPE = {
        "insert into" => "INSERT",
        "update" => "UPDATE",
        "delete from" => "DELETE",
        "from" => "SELECT"
      }.freeze

      def self.topic
        ACTIVE_RECORD_SQL_EVENT
      end

      def self.ignore_pattern
        # TODO: Switch to use or expose IGNORE_QUERY_MATCHES as config
        ::NPlusOneControl.ignore
      end

      def parse_log(pattern, _name, _start, _finish, _message_id, values)
        return if PARSABLE_EVENT_NAME.include? values[:name]
        return if values[:sql].match?(self.class.ignore_pattern)

        return unless pattern.nil? || (values[:sql] =~ pattern)

        sql = values[:sql]

        matches = sql.match(EXTRACT_TABLE_RXP)
        return if matches.nil?

        detail = {
          target: matches[2],
          action: QUERY_PART_TO_TYPE[matches[1].downcase],
          raw: sql
        }

        if NPlusOneControl.backtrace_cleaner && NPlusOneControl.verbose
          source = extract_query_source_location(caller)
          detail[:raw_with_backtrace] = "#{sql}\n    ↳ #{source.join("\n")}" unless source.empty?
        end

        ::NPlusOneControl::Query.new(detail)
      end
    end
  end
end
