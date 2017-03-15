# Load the config manager incase it hasn't been laoded yet.
require "ConfigManager"

# =============================================================================
# FileManager - Handle file related tools and things.
# =============================================================================
class FileManager

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("FileManager")

	# -------------------------------------------------------------------------
	# Build an absolute file path.
	# -------------------------------------------------------------------------
	def self.get_path(relative_path)
		return "#{ConfigManager.get("presto_root")}/#{relative_path}"
	end

	# -------------------------------------------------------------------------
	# Check if a path looks like a directory request.
	# -------------------------------------------------------------------------
	def self.check_for_directory(request_path)
		if /\/$/.match(request_path)
			request_path += "index.html"
		end

		if File.directory?(request_path)
			request_path += "/index.html"
		end
		return request_path
	end

end