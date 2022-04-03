# frozen_string_literal: true

module NPlusOneControl
  class Query
    def initialize(detail = {})
      @detail = detail
      @target, @action, @raw, @raw_with_backtrace = @detail.values_at(:target, :action, :raw, :raw_with_backtrace)
    end

    def to_usage
      "  #{@target} (#{@action})"
    end

    def truncated
      # Only truncate query, leave tracing (if any) as is
      parts = @raw.split(/(\s+↳)/)

      parts[0] =
        if NPlusOneControl.truncate_query_size < 4
          "..."
        else
          parts[0][0..(NPlusOneControl.truncate_query_size - 4)] + "..."
        end

      parts.join
    end

    def to_s
      @raw_with_backtrace
    end
  end
end
