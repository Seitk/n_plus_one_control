# frozen_string_literal: true

module NPlusOneControl
  module Collectors
    class Mongoid < Base
      MONGODB_CMD_EVENT = 'cmd.mongodb'.freeze

      LOG_PLATFORM_MONGO = 'MONGODB'.freeze
      LOG_SEGMENT_START = 'STARTED'.freeze
      LOG_CMD_PREFIX = /([a-z0-9_]+)\..+/.freeze

      QUERY_REGEX_INSERT = /"(insert)"=>"([a-z0-9_]+)".+"(documents)"=>(.+)/.freeze
      QUERY_REGEX_DELETE = /"(delete)"=>"([a-z0-9_]+)".+"(deletes)"=>(.+), "\$db"=>"([a-z0-9_]+)"/.freeze
      QUERY_REGEX_DISTINCT = /"(distinct)"=>"([a-zA-Z0-9\-_]+)".+"(query)"=>(.+), "\$db"=>"([a-z0-9_]+)"/.freeze
      QUERY_REGEX_FIND_INSERT_COUNT = /"(find|insert|count)"=>"([a-z0-9_]+)".+"(filter|query)"=>(.+), "\$db"=>"([a-z0-9_]+)"/.freeze

      def self.topic
        MONGODB_CMD_EVENT
      end

      def parse_log(pattern, _name, _start, _finish, _message_id, values)
        platform, _, cmd_with_db, event, payload = values.split('|').map(&:strip)
        return unless platform.try(:strip) == LOG_PLATFORM_MONGO

        query = nil

        case event.try(:strip)
        when LOG_SEGMENT_START
          raw = payload.try(:strip)
          db = cmd_with_db[LOG_CMD_PREFIX, 1]
          query = parse_operation(db, raw)
        end

        query
      end

      private

      def parse_operation(db, raw)
        [QUERY_REGEX_FIND_INSERT_COUNT, QUERY_REGEX_DISTINCT, QUERY_REGEX_INSERT, QUERY_REGEX_DELETE].each do |reg|
          cmd, collection, _, criteria = raw.scan(reg).flatten
          if cmd.present?
            return ::NPlusOneControl::Query.new({
              target: [db, collection].join('.'),
              action: cmd,
              raw: raw
            })
          end
        end

        nil
      end
    end
  end
end
