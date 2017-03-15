require "Os"

# =============================================================================
# Gems - This ANJI gives control over the system's Ruby Gems.
# =============================================================================
class Gems < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Gems")

    # --------------------------------------------------------------------------
    # List the Gems on the system currently.
    # --------------------------------------------------------------------------
    def list_gems(options)
        
        # Get the Gem list.
        gem_list = `gem list`
        
        # If we need to parse the list into an HTML format then do this.
        if options["format"] == "html"
            gem_list_html = []
            gem_list = gem_list.split(/\r?\n/)
            gem_list.each do |gem_details|
                gem_name = gem_details[/^([\w-]+) \(.*\)$/, 1]
                gem_list_html << "<li>#{gem_details} - <span class='link' onclick='uninstall_gem(\"#{gem_name}\");'>Uninstall</span></li>"
            end
            gem_list = "<ul>#{gem_list_html.join("")}</ul>"
        end
        
        # Return the Gem list.
        return gem_list
        
    end
    
    # --------------------------------------------------------------------------
    # Run an update on the currently installed Gems.
    # --------------------------------------------------------------------------
    def update_gems()
        
        # Run the command and capture the response.
        response = `gem update`
        
        # Pull out the final line and return it.
        response = response.split(/\r?\n/)[-1]
        return response
    end
    
    # --------------------------------------------------------------------------
    # Try to install a new Gem.
    # --------------------------------------------------------------------------
    def install_gem(options)
        
        # Get the Gem name.
        gem_name = options["gem_name"]
        
        # Check we have a name and try to install it.
        response = "No Gem name was given"
        if gem_name != nil && gem_name != ""
            response = Os.run("gem install #{gem_name}")
        end
        
        # If we need to format for HTML then we do that.
        if options["format"] == "html"
            response.gsub!(/[\r\n]+/, "<br>")
        end
        
        # Return the response.
        return response
        
    end
    
    # --------------------------------------------------------------------------
    # Try to uninstall a Gem.
    # --------------------------------------------------------------------------
    def uninstall_gem(options)
        
        # Get the Gem name.
        gem_name = options["gem_name"]
        
        # Check we have a name and try to uninstall it.
        response = "No Gem name was given"
        if gem_name != nil && gem_name != ""
            response = `gem uninstall #{gem_name}`
        end
        
        # Return the response.
        return response
    
    end
    
    # --------------------------------------------------------------------------
    # Clean up the old Gem versions.
    # --------------------------------------------------------------------------
    def clean_up_gems()
        
        # Run the clean up and capture the response.
        response = `gem cleanup`

        # Pull out the final line and return it.
        response = response.split(/\r?\n/)[-1]
        return response

    end
    
    # --------------------------------------------------------------------------
    # Get a list of available Gem versions.
    # --------------------------------------------------------------------------
    def get_versions(options)

        # Get the Gem name.
        gem_name = options["gem_name"]
        @@LOGGER.debug("Got Gem name #{gem_name}")
        
        # Check we have a name and try to uninstall it.
        response = "No Gem name was given"
        if gem_name != nil && gem_name != ""
            response = `gem list \\b#{gem_name}\\b --remote --all`
            @@LOGGER.debug("Response was #{response}")
        end
        
        # If we want to format as HTML then do this.
        if options["format"] == "html"
            @@LOGGER.info("Formatting version list as HTML")
            @@LOGGER.debug("Looking for new lines in response #{response.gsub(/\n/, "\\n").gsub(/\r/, "\\r")}")
            response.gsub!(/[\r\n]+/, "<br>")
            @@LOGGER.debug("Formatted response to #{response}")
        end
        
        # Return the response.
        return response
     
    end
    
    # -------------------------------------------------------------------------
    # Return the public functions this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return [
            "list_gems",
            "update_gems",
            "install_gem",
            "uninstall_gem",
            "clean_up_gems",
            "get_versions"
        ]
    end

end