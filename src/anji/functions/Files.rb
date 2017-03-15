# =============================================================================
# Files - Handle file and directories.
# =============================================================================
class Files < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Files")

    # -------------------------------------------------------------------------
    # Get a directory listing.
    # -------------------------------------------------------------------------
    def get_directory_listing(args)

        # Get the requested file path.
        file_path    = args["file_path"] || args["path"]
        include_dots = is_true(args["include_dots"])

        # Get the directory listing.
        directory_listing = Dir.entries("#{ConfigManager.get("presto_root")}/#{file_path}")

        # Remove "." and ".." if requested.
        if !include_dots
            directory_listing.delete(".")
            directory_listing.delete("..")
        end

        # Return the directory listing.
        return directory_listing

    end

    # -------------------------------------------------------------------------
    # Get entire file content.
    # -------------------------------------------------------------------------
    def get_file_content(args)

        # Get the requested file path.
        file_path = args["file_path"] || args["path"] || args["file"]
        file_path = file_path.gsub(/%PRESTO%/, ConfigManager.get_presto_root())
        @@LOGGER.debug("Looking for file path #{file_path}")

        file_contents = File.read(file_path)
        
        # Check if we need to format for HTML.
        if args["format"] == "html"
            file_contents.gsub!(/[\r\n]+/, "<br>")
        end

        return file_contents
    end

    def get_presto_root()
        return ConfigManager.get("presto_root").gsub(/\\/, "/")
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return ["get_file_content"]
    end

end