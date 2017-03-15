# =============================================================================
# Python - Run a Python script.
# =============================================================================
class Python < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Python")

	def self.do_run_script(file_path, threaded, arg_string)
		system("py #{file_path} #{arg_string}")
		return "ok"
	end

	# -------------------------------------------------------------------------
	# Run a Python script.
	# -------------------------------------------------------------------------
	def run_python_script(args)

		# Get the script name.
		script_name = args["name"]

		# Get the relative path.
		relative_path = args["path"]

		if relative_path == nil
			relative_path = "python"
		end

		script_path = "#{relative_path}/#{script_name}.py"

		threaded = args["threaded"]

		script_args = args["args"]

		if script_args == nil
			script_args = ""
		end

		# Run the script and return the response.
		@@LOGGER.info("Running Python script '#{script_path}'")
		if script_args != ""
			@@LOGGER.info("Using args string '#{script_args}'")
		end

		result = Python.do_run_script(script_path, threaded, script_args)

		return result
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return ["run_python_script"]
	end

end