# =============================================================================
# Project - Description.
# =============================================================================
class Project < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Project")

	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def record_support(args)
		presto_root = ConfigManager.get("presto_root")
		output_file = "#{presto_root}/support.txt"
		@@LOGGER.info("Recording supporting installers to '#{output_file}'")
		File.open(output_file, "w") do |file|
			file.write("Current software installers supporting this project:\n")
			Dir.entries("#{presto_root}/installers").select do |file_name|
				if !file_name[/^\.\.?$/]
					file.write("- #{file_name}\n")
				end
			end
		end
		return "Done"
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return ["record_support"]
	end

end