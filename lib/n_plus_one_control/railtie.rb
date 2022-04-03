# frozen_string_literal: true

module NPlusOneControl # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    initializer "n_plus_one_control.backtrace_cleaner" do
      ActiveSupport.on_load(:active_record) do
        NPlusOneControl.backtrace_cleaner = lambda do |locations|
          ::Rails.backtrace_cleaner.clean(locations)
        end
      end
    end

    initializer "n_plus_one_control.mongo_logger_proxy" do
      if Rails.env.test?
        Rails.application.configure do
          config.after_initialize do
            # Change Mongoid log destination and/or level
            Mongo::Logger.logger = Logger.new(STDOUT).tap do |logger|
              logger.level = Logger::DEBUG
              logger.formatter = proc { |severity, datetime, progname, msg|
                ::NPlusOneControl::Collector.mongoid.publish(msg)
              }
            end
          end
        end
      end
    end
  end
end
