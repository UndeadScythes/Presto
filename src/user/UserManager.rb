# Include our user related exceptions.
require "NoUserException"
require "PasswordMismatchException"

# Include the Crypto, FIleManager and HTTP classes.
require "Crypto"
require "Http"
require "FileManager"

# =============================================================================
# UserManager - Handle users, login/logout requests and track permissions.
# =============================================================================
class UserManager

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("UserManager")

	# Track the logged in users.
	@@USERS = Hash.new

	# -------------------------------------------------------------------------
	# Try to log the user in.
	# -------------------------------------------------------------------------
	def self.login(args)

		# Get the username and password.
		username = args["username"]
		password = args["password"]

		# Check if we have a user matching this username.
		user_details = @@USERS[username]
		if user_details == nil
			raise NoUserException
		end

		# Determine the user's password hash.
		begin
			password = Crypto.hash_password(password, user_details)
		rescue NoHashMethodException
			raise PasswordMismatchException
		end

		# Check the user's password details.
		if user_details["password"] == password

			# Generate a auth token for the user and store it.
			user_details["auth_token"] = auth_token = Crypto.generate_auth_token(username)

			# See if we have a landing page for the user.
			landing_page = user_details["landing_page"] || ""
			landing_page = FileManager.check_for_directory(landing_page)

			# Build a response to serve.
			headers  = Http.set_cookie("auth_token", auth_token)
			response = Http.get_redirect(landing_page, headers)
		
		else
			raise PasswordMismatchException
		end

		return response

	end

	# -------------------------------------------------------------------------
	# Load a user from a hash.
	# -------------------------------------------------------------------------
	def self.load_user(user_details)

		# Let's see what we have.
		username = user_details["username"]

		if username != nil

			@@USERS[username] = Hash.new

			user_details.each do |key, value|
				if key != "username"
					@@USERS[username][key] = value
				end
			end

		end

	end

	# -------------------------------------------------------------------------
	# Check the existing config settings for user login details.
	# -------------------------------------------------------------------------
	def self.load_users_from_config()

		# See if we have any users.
		config_users = ConfigManager.get_array("users")
		if config_users != nil

			# Load each user.
			config_users.each do |user_details|
				self.load_user(user_details)
			end

		end

	end

	# -------------------------------------------------------------------------
	# Get a user's auth token.
	# -------------------------------------------------------------------------
	def self.get_auth_token(username)
		user = @@USERS[username]
		return (user ? user["auth_token"] : nil)
	end

	# -------------------------------------------------------------------------
	# Check if the user has a valid auth token.
	# -------------------------------------------------------------------------
	def self.check_auth_token(cookies)
		
		auth_token = cookies["auth_token"]
		@@LOGGER.debug("User has given us #{auth_token}")

		valid_token = false
		if auth_token != nil
			username = self.get_username_from_auth_token(auth_token)
			if username != nil
				our_auth_token = UserManager.get_auth_token(username)
				if our_auth_token != nil
					our_auth_token.sub!(/\r?\n$/, "")
				end
				@@LOGGER.debug("We have auth token #{our_auth_token}")
				if auth_token == our_auth_token
					valid_token = true
				end
			end
		end

		@@LOGGER.debug("Auth token is valid: #{valid_token}")
		return valid_token

	end

	def self.logout(args)
		# username = args.get_username(args)
		# FIXME: Do a real logout.
	end

	def self.write_auth_tokens_to_file()
		user_list = []
		@@USERS.each do |username, user_details|
			@@LOGGER.debug("Checking #{username} for auth token")
			if user_details["auth_token"] != nil
				@@LOGGER.debug("Auth token found, writing to file")
				user_list << "\"#{username}\":\"#{user_details["auth_token"]}\""
			end
		end
		File.open(FileManager.get_path("auth_tokens.json"), "w") do |file|
			file.write("{#{user_list.join(",")}}")
		end
	end

	def self.read_auth_tokens_from_file()
		auth_token_path = FileManager.get_path("auth_tokens.json")
		if File.exist?(auth_token_path)
			@@LOGGER.info("Loading auth tokens from file")
			auth_tokens = File.read(auth_token_path)
			begin
				auth_tokens = JSON.parse(auth_tokens)
				auth_tokens.each do |key, value|
					if @@USERS[key] == nil
						@@USERS[key] = Hash.new
					end
					@@USERS[key]["auth_token"] = value
				end
			rescue => error
				@@LOGGER.warn("Auth token JSON was corrupt:")
				@@LOGGER.warn(error)
			end
		else
			@@LOGGER.info("No auth token file found")
		end
	end

	def self.get_username_from_auth_token(auth_token)
		username_match = auth_token.match(/^presto_(.*)_auth_token_.*$/)
		return (username_match ? username_match.captures[0] : nil)
	end

	def self.has_access(username, request_path)
		directory_access = @@USERS[username]["directory_access"] || []
		directory_access += ConfigManager.get_array("public_access") || []
		@@LOGGER.debug("Checking access for #{request_path}")
		has_access = false
		directory_access.each do |directory|
			if request_path[/^#{directory}/]
				has_access = true
			end
		end
		if has_access == false
			if request_path[/^#{@@USERS[username]["landing_page"]}/]
				has_access = true
			end
		end
		@@LOGGER.debug("User has access: #{has_access}")
		return has_access
	end

end