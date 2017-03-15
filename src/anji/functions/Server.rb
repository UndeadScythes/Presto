# =============================================================================
# Server - Description.
# =============================================================================
class Server < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Server")

	@@DEFAULT_RESTART_TIMEOUT = 1

	def restart(args)

		# Get the restart timeout.
		restart_timeout = args["timeout"] || @@DEFAULT_RESTART_TIMEOUT

		# Write auth tokens to file.
		UserManager.write_auth_tokens_to_file()

		# Start the restart timeout.
		Thread.new do
			sleep(restart_timeout)
			@@LOGGER.info("Restarting now")
			Kernel.exit
		end

		# Log to console and return.
		@@LOGGER.info("Restarting server in #{restart_timeout} second#{restart_timeout == 1 ? "" : "s"}")
		return "Restarting"

	end

	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def set_logging_level(args)
		log_level = args["level"]
		response = "Logging level set to '#{log_level}'"
		case log_level
			when "fatal"
				LogManager.set_current_log_level(Logger::FATAL)
			when "error"
				LogManager.set_current_log_level(Logger::ERROR)
			when "warn"
				LogManager.set_current_log_level(Logger::WARN)
			when "info"
				LogManager.set_current_log_level(Logger::INFO)
			when "debug"
				LogManager.set_current_log_level(Logger::DEBUG)
			else
				response = "Unknown log level '#{log_level}'"
				@@LOGGER.warn(response)
		end
		return response
	end
    
    def ping()
        return "pong"
    end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return ["set_logging_level", "restart", "ping"]
	end

end