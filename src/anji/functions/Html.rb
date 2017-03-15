# Include the CGI module for unescaping
external_require "cgi"

# =============================================================================
# Html - Build HTML elements and structures.
# =============================================================================
class Html < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Html")

	def self.do_array_to_ul(array, embed = "%VALUE%")
		html = "<ul>"

		if array != nil

			array.each do |value|
				html += "<li>#{embed.gsub("%VALUE%", value)}</li>"
			end

		end

		html += "</ul>"

		return html
	end

	# -------------------------------------------------------------------------
	# Convert an array to an HTML UL list.
	# -------------------------------------------------------------------------
	def array_to_ul(args)

		# Get the array.
		array_name = args["array_name"] || args["array"]
		array = ConfigManager.get(array_name)

		# See if an embed was provided.
		embed = args["embed"]
		if embed == nil
			embed = "%VALUE%"
		end

		return Html.do_array_to_ul(array, embed)

	end

	def self.do_array_to_select(array, id="select_#{Time.now.to_s}", onchange = "", select_size = 1)
		html = "<select id='#{id}' size='#{select_size}'#{onchange}>"
		if array != nil
			array.each do |value|
				html += "<option value='#{value}'>#{value}</option>"
			end
		end
		html += "</select>"
		return html
	end

	# -------------------------------------------------------------------------
	# Convert an array to an HTML SELECT.
	# -------------------------------------------------------------------------
	def array_to_select(args)

		# Get the array.
		array_name = args["array_name"] || args["name"]
		id         = args["id"]
		array = ConfigManager.get_array(array_name)
		select_size = args["size"] || 1
		onchange = args["onchange"]
		onchange = (onchange ? " onchange='#{onchange}(event);'" : "")

		return Html.do_array_to_select(array, id, onchange, select_size)

	end

	# -------------------------------------------------------------------------
	# Get a argument passed as a query string to the page.
	# -------------------------------------------------------------------------
	def get_query_string_arg(args)
		value    = args[args["name"]]
		fallback = args["fallback"]
		return CGI::unescape(value || fallback || "")
	end

	# -------------------------------------------------------------------------
	# Embed an HTML snippet.
	# -------------------------------------------------------------------------
	def embed_html(args)

		public_html_root = ConfigManager.get("public_html_root")

		file_name = args["file"]

		embed_folder = args["folder"]
		if embed_folder == nil
			embed_folder = "/snippets"
		end

		file_path = "#{public_html_root}#{embed_folder}/#{file_name}"
		response = ""
		@@LOGGER.debug("Checking if file exists: '#{file_path}'")
		if File.exist?(file_path)
			if File.directory?(file_path)
				@@LOGGER.error("Requested file was a directory")
				return ""
			end
			@@LOGGER.debug("File exists, embedding")
			file = File.open(file_path, "rb")
			response = file.read
			file.close
			response = AnjiManager.parse(response, args)
		end
		return response
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return []
	end

end