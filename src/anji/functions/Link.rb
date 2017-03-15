# =============================================================================
# Link - Description.
# =============================================================================
class Link < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Link")

	def self.link_css(url)
		url.sub!(/\.css$/, "")
        return "<link rel='stylesheet' type='text/css' href='#{url}.css'>"
    end
    
    def self.link_js(url)
    	url.sub!(/\.js$/, "")
        return "<script src='#{url}.js'></script>"
    end
    
	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def link_css(args)

		file_name = args["file"] || args["path"]

		file_name.sub!(/\.css$/, "")

		return "<link rel='stylesheet' type='text/css' href='#{file_name}.css'>"
	end

	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def link_js(args)

		file_name = args["file"] || args["path"]

		file_name.sub!(/\.js$/, "")

		return "<script src='#{file_name}.js'></script>"
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return []
	end

end