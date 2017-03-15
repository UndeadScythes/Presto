# =============================================================================
# Presto - Presto webserver specific functions for engaging the front end.
# =============================================================================
class Presto < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Presto")

    # -------------------------------------------------------------------------
    # Embed the system files.
    # -------------------------------------------------------------------------
    def presto_include(arguments)
        
        # Get the public root folder and the Presto JS folder.
        public_html_root = ConfigManager.get("public_html_root")
        presto_js_folder = File.join(public_html_root, "js")
        
        # Embed each file in the html.
        response = ""
        Dir.entries(presto_js_folder).each do |file_path|
            response += Strip.embed_js(File.join(presto_js_folder, file_path), arguments)
        end
        
        # Return the complete string.
        return response
        
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return []
    end

end