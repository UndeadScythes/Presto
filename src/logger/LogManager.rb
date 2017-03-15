external_require "logger"

require_relative "LogOutput"

# =============================================================================
# LogManager - Handle logging in the software, either to console or to file.
# =============================================================================
class LogManager

    # Set the default log level.
    @@default_log_level = Logger::ERROR
    
    # Keep a reference to all the loggers created.
    @@LOGGERS = Hash.new
    
    # -------------------------------------------------------------------------
    # Get a logger or create one if it does not exist yet.
    # -------------------------------------------------------------------------
    def self.get_logger(log_reference, logging_level = @@default_log_level, deprecated_parameter = nil)
        
        # Handle the deprecated parameter.
        if deprecated_parameter != nil
            logging_level = deprecated_parameter
        end
            
        
        # Check if we have the logger already, otherwise create a new one.
        logger = @@LOGGERS[log_reference]
        if logger == nil

            @@LOGGERS[log_reference] = logger = Logger.new(LogOutput.new(log_reference))
            logger.level = logging_level
            logger.formatter = proc do |severity, datetime, progname, message|
                "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} [#{log_reference}:#{severity}] #{message}\n"
            end
            logger.debug("Logger created")

        end

        # Log the depreacted parameter use.
        if deprecated_parameter != nil
            logger.warn("Deprecated parameter was used to initialise this logger")
        end

        return logger

    end

    # -------------------------------------------------------------------------
    # Set the logging level of all current loggers.
    # -------------------------------------------------------------------------
    def self.update_log_levels(logging_level)
        @@LOGGERS.each do |log_reference, logger|
            logger.level = logging_level
        end
    end

    # -------------------------------------------------------------------------
    # Set the logging level for all loggers.
    # -------------------------------------------------------------------------
    def self.set_current_log_level(logging_level)
        @@default_log_level = logging_level
        if logging_level == Logger::DEBUG
            $DEBUG = true
        else
            $DEBUG = false
        end
        self.update_log_levels(logging_level)
    end

    # -------------------------------------------------------------------------
    # Get the current default logging level.
    # -------------------------------------------------------------------------
    def self.get_default_log_level()
        return @@default_log_level
    end

end