# =============================================================================
# Anji - Meet the ANJI - Anji is Not JSP, Idiot - a sure fire way to get stuff
# done on the webserver. ANJIs can be invoked from the server and the client.
# =============================================================================
class Anji

	# Create a logger for the ANJI superclass.
	@@LOGGER = LogManager.get_logger("Anji")

	# -------------------------------------------------------------------------
	# Run this ANJI.
	# -------------------------------------------------------------------------
	def run(args)

		# Get the command.
		cmd = args["cmd"]

		# Set a default empty string response.
		response = ""

		begin

			# First check that we actually have the specified method.
			if respond_to?(cmd)

				# Now count how many arguments we need.
				arg_count = method(cmd).arity
				@@LOGGER.debug("Command #{cmd} takes #{arg_count} argument#{arg_count == 1 ? "" : "s"}")

				# Call the method passing the arguments if required.
				if arg_count == 0
					response = send(cmd)
				elsif arg_count == 1
					response = send(cmd, args)
				else

					# If the method takes more than one argument then we have a problem!
					@@LOGGER.error("Command #{cmd} takes #{arg_count} arguments")

				end

			else

				# If we could not find a corresponding method then log an error.
				@@LOGGER.error("Command not recognised: #{cmd}")

			end

		# Catch any errors whilst running the method and log them.
		rescue => error
			@@LOGGER.error("There was an error whilst running #{cmd}: #{error}")
		end

		# Return the response.
		return response

	end

	# -------------------------------------------------------------------------
	# Get the "truthiness" of a value and fallback to a default setting.
	# -------------------------------------------------------------------------
	def is_true(value, default = false)

		result = default

		# Check first for nil.
		if value != nil

			# Get the first char of the lower cased value.
			value = value.downcase[0, 1]

			# Check for "y" and "t".
			if value == "y" || value == "t"
				result = true
			elsif value == "n" || value == "f"
				result = false
			end

		end

		# Return the result.
		return result

	end

end