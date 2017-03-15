# Include an exception for silly errors.
require "NoHashMethodException"

# Get a nice base 64 conversion tool.
external_require "base64"

# =============================================================================
# Crypto - Description.
# =============================================================================
class Crypto

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Crypto")

	# -------------------------------------------------------------------------
	# Hash a password.
	# -------------------------------------------------------------------------
	def self.hash_password(password, salt_parameters)
		hash_method = salt_parameters["hash_method"] || "none"
		hashed_password = ""
		case hash_method
			when "none"
				hashed_password = password
			else
				raise NoHashMethodException
		end
		return hashed_password
	end

	# -------------------------------------------------------------------------
	# Generate a unique token.
	# -------------------------------------------------------------------------
	def self.generate_auth_token(username)
		time = Time.now
		@@LOGGER.debug("Time at #{time}")
		base_64_time = Base64.encode64(time.to_s).sub(/[\r\n]+$/, "")
		@@LOGGER.debug("Time as string #{time.to_s}")
		@@LOGGER.debug("Time in B64 #{base_64_time}")
		return "presto_#{username}_auth_token_#{base_64_time}"
	end

	def self.get_base64_time_stamp() 
		return Base64.encode64(Time.now.to_s)
	end

end