# =============================================================================
# Strip - Build HTML elements and structures.
# =============================================================================
class Strip < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Strip")

	def self.embed_js(file_path, args)
		js_code = ""
		if File.exists?(file_path)
			if File.directory?(file_path)
				@@LOGGER.warn("File path was a directory")
			else	
				js_code = File.read(file_path)
				js_code = AnjiManager.parse(js_code, args)
				#js_code.gsub!(/^\s*\/\/.*$/, "")
				#js_code.gsub!(/\s*\/\/.*$/, "")
				#js_code.gsub!(/\/*.*?\//, "")
				#js_code.gsub!(/^\s*(?=[^\s])/, "")
				#js_code.gsub!(/^(?<=[^\s])\s*/, "")
			end
		else
			@@LOGGER.warn("Could not find JS file #{file_path}")
		end
		return "<script>#{js_code}</script>"
	end


	# -------------------------------------------------------------------------
	# Strip guff from a JS file and embed it in a page.
	# -------------------------------------------------------------------------
	def embed_js(args)
		file_path = args["file"]
		file_path = "#{ConfigManager.get("presto_root")}/#{file_path}"
		js_code = ""
		if File.exists?(file_path)
			js_code = File.read(file_path)
			js_code = AnjiManager.parse(js_code, args)
			#js_code.gsub!(/^\s*\/\/.*$/, "")
			#js_code.gsub!(/\s*\/\/.*$/, "")
			#js_code.gsub!(/\/*.*?\//, "")
			#js_code.gsub!(/^\s*(?=[^\s])/, "")
			#js_code.gsub!(/^(?<=[^\s])\s*/, "")
		else
			@@LOGGER.warn("Could not find JS file #{file_path}")
		end
		return "<script>#{js_code}</script>"
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return []
	end

end