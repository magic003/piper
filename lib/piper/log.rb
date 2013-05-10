require 'logger'

module Piper
  # This +Log+ module provides the logger solution for this project. Any class
  # can add log function by including it. A ruby {Logger} object can be 
  # obtained by calling the {#logger} method. Due to this mixin magic, the 
  # name of the container class is set on the +logger+ object, so each log 
  # message contains the specific classname.
  #
  # == Example
  # 
  #   class Foo
  #     include Log
  #
  #     def run
  #       logger.warn "About to run..."
  #     end
  #   end
  #
  # == Customization
  #
  # By default, +$stdout+ is used as the +logdev+. Programmer can customize 
  # this, as well as for properties +shift_age+, +shift_size+, and +level+. 
  #
  #   # default values
  #   logdev = $stdout
  #   shift_age = 'monthly'
  #   shift_size = 1048576
  #   level = Logger::ERROR
  #
  # Properties can be changed by:
  #
  #   # Customize
  #   Log.logdev = 'app.log'
  #   Log.shift_age = 'daily'
  #   Log.shift_size = 4096
  #   Log.level = Logger::WARN
  #
  # The above code has global effects. If you only want to change them in a
  # particular class, you can change the object obtained from +logger+ method.
  module Log
    # Obtains a logger for the enclosed class.
    #
    # @return [Logger] logger with current class name as the +progname+
    def logger
      @logger ||= Log.logger_for(self.class.name)
    end
    
    class << self

      attr_writer :logdev, :shift_age, :shift_size, :level

      # Creates a logger with the specified name.
      #
      # @return [Logger]
      def logger_for(name)
        @loggers[name] ||= configure_logger_for(name)
      end

      private

      # Creates and configures a logger.
      #
      # @return [Logger]
      def configure_logger_for(name)
        logger = Logger.new(@logdev, @shift_age, @shift_size)
        logger.level = @level
        logger.progname = name
        logger.formatter = formatter
        logger
      end

      # Creates a formatter which customizes the original formatter
      # by adding method name into the program name.
      #
      # @return [Logger::Formatter]
      def formatter 
        original_formatter = Logger::Formatter.new
        Proc.new do |severity, datetime, progname, msg|
          original_formatter.call(severity, datetime, 
                                  "#{progname}##{caller_method}",
                                  msg.dump)
        end
      end
      
      # Gets the caller method name.
      # Copied from {https://gist.github.com/mikezter/540132 this gist}.
      #
      # @return [String]
      def caller_method
        at = caller(7).first  # 7 is get by test and hardcoded here
        if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
          Regexp.last_match[3]
        end
      end
    end

    # Use a hash to cache a unique logger per class
    @loggers = {}

    # default settings
    @logdev = $stdout
    @shift_age = 'monthly'
    @shift_size = 1048576
    @level = Logger::ERROR

  end
end
