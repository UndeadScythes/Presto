# Make sure the main ANJI class is included.
require "Anji"

# We need some HTTP protocol help here.
require "Http"

# =============================================================================
# AnjiManager - Handles all ANJIs on the server.
# =============================================================================
class AnjiManager

	# Keep a record of all our initialised ANJIs.
	# We store the class name of the ANJI under a key for each function the
	# ANJI can provide.
	@@ANJIS = Hash.new

	# Get a new logger for this class.
	@@LOGGER = LogManager.get_logger("AnjiManager")

	# Store the regex that will match ANJIs.
	# This will match strings in the form:
	# <ANJI Class.method({"json":"args"})/>
	@@ANJI_REGEX       = /<ANJI [\w.]+\(.*?\)\/?>/
	@@ANJI_PARTS_REGEX = /<ANJI ([\w.]+)\((.*?)\)\/?>/

	def self.load_anji_functions(anji_name)

		# Call the get_names function on the ANJI class to discover what
		# functions it can provide.
		@@LOGGER.info("Getting functions from #{anji_name}")
		begin
			anji_names = Object.const_get(anji_name).get_names
		rescue
			@@LOGGER.error("Could not get ANJI functions from #{anji_name}")
			return
		end

		# Add each function as a key mapping to the name of the ANJI class.
		anji_names.each do |function_name|
			@@LOGGER.info("Registering function #{anji_name}.#{function_name}")
			@@ANJIS[function_name] = anji_name
		end
	end

	# -------------------------------------------------------------------------
	# Load all the ANJIs in the specified folder and record their class names.
	# -------------------------------------------------------------------------
	def self.load_all(anji_directory = "anji/functions")

		# Add the directory provided into the server's load path.
		$LOAD_PATH << anji_directory

		# Loop oer all Ruby classes in the directory.
		Dir["#{anji_directory}/*.rb"].each do |file_name|

			# Remove the directory so we do not need to call a require_relative
			file_name.sub!("#{anji_directory}/", "")
			require file_name

			# Now remove the ".rb" extension so we can call a method on the
			# class.
			file_name.sub!(".rb", "")

			self.load_anji_functions(file_name)
			
		end

	end

	# -------------------------------------------------------------------------
	# Reload all the registered ANJIs.
	# -------------------------------------------------------------------------
	def self.reload()

		# Loop oer all Ruby classes in the directory.
		@@LOGGER.info("Reloading all registered ANJIs")
		reloaded = Hash.new
		count = 0
		@@ANJIS.clone.each do |key, value|
			@@LOGGER.debug("Checking ANJI function '#{key}' -> '#{value}'")
			if reloaded[value] == nil
				@@LOGGER.info("Reloading ANJI '#{value}'")
				load "#{value}.rb"
				reloaded[value] = true
				count += 1
				self.load_anji_functions(value)
			end
		end

		message = "#{count} ANJIs reloaded"

		@@LOGGER.info(message)

		return message

	end

	# -------------------------------------------------------------------------
	# Get the class name of a particular ANJI.
	# -------------------------------------------------------------------------
	def self.get(anji_name)
		return @@ANJIS[anji_name]
	end

	# -------------------------------------------------------------------------
	# Invoke an ANJI.
	# -------------------------------------------------------------------------
	def self.invoke(anji_name, args)
		
		# Check if we have a class in our ANJI name.
		if anji_name["\."]
			@@LOGGER.debug("Found an ANJI call including a class name #{anji_name}")
			anji, anji_name = anji_name.split(".")
		else
			@@LOGGER.debug("Looking for ANJI '#{anji_name}'")
			anji = self.get(anji_name)
		end

		# Add the correct command string to the args.
		args["cmd"] = anji_name

		# Get the ANJI and check that it exists.
		if anji != nil
			@@LOGGER.info("Running ANJI '#{anji}.#{anji_name}'")
			begin
				result = Object.const_get(anji).new.run(args)
			rescue => error
				@@LOGGER.warn("Failed invoking ANJI '#{anji}.#{anji_name}': #{error}")
				result = ""
			end
		else
			@@LOGGER.warn("Could not find ANJI serving '#{anji_name}'")
			result = ""
		end

		# Look for standard parameters.
		output = args["output"]
		if output != nil
			@@LOGGER.debug("Stroring result in key '#{output}'")
			ConfigManager.set(output, result)
			result = ""
		end
		redirect = args["redirect"]
		if redirect != nil
			@@LOGGER.debug("Redirecting to file: '#{redirect}'")
			response = Http.get_redirect(redirect)
		else
			response = result
		end
		return response
	end

	# -------------------------------------------------------------------------
	# Parse a string.
	# -------------------------------------------------------------------------
	def self.parse(string, request_properties)

		# Detect all of the ANJIs in the string.
		anji_list = string.scan(@@ANJI_REGEX)

		# Loop over the ANJIs, evaluate and replace each one.
		anji_list.each do |full_anji_string|

			# Parse the ANJI into its parts.
			anji_parts = @@ANJI_PARTS_REGEX.match(full_anji_string)
			anji_name = anji_parts[1]
			args      = anji_parts[2]

			# Now check if any arguments were provided.
			begin

				# Sanity check the args.
				if !args[/^\{.*\}$/]
					@@LOGGER.warn("Sanitised JSON formatting as arguments were passed without {...}")
					args = "{#{args}}"
				end
				args = (args == "" ? Hash.new : JSON.parse(args))

			rescue
				@@LOGGER.error("Could not parse ANJI args: #{args}")
				return string
			end

			# Add the global args.
			request_properties.each do |key, value|
				args[key] = value
			end
			args["cmd"] = anji_name

			# Do the actual ANJI parsing.
			@@LOGGER.debug("Parsing ANJI: '#{full_anji_string}'")
			result = self.invoke(anji_name, args)
			if result == nil
				@@LOGGER.debug("No response from ANJI")
			else
				@@LOGGER.debug("Result of ANJI: '#{result}'")
				string.sub!(full_anji_string, result)
			end

		end

		return string

	end

	# -------------------------------------------------------------------------
	# Get an array with all the loaded ANJIs.
	# -------------------------------------------------------------------------
	def self.get_anji_list()
		return @@ANJIS.keys
	end

end