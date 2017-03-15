# =============================================================================
# Environment - Return values related to the environment.
# =============================================================================
class Environment < Anji

    # -------------------------------------------------------------------------
    # Get the current request string.
    # -------------------------------------------------------------------------
    def get_current_request(args)
        return args["request_string"]
    end

    # -------------------------------------------------------------------------
    # Get a list of registered ANJIs.
    # -------------------------------------------------------------------------
    def get_anji_list(args)
        return AnjiManager.get_anji_list()
    end

    # -------------------------------------------------------------------------
    # Reload all the registered ANJIs.
    # -------------------------------------------------------------------------
    def reload_anjis(args)
        return AnjiManager.reload()
    end
    
    def get_query_string_arg(args)
        name = args["name"]
        @@LOGGER.debug("Looking for query string arg #{name}")
        result = ""
        if name != nil
            result = args[name] || ""
            @@LOGGER.debug("Found query string arg value was #{result}")
        end
        return result
    end
    
    def get_variable_list()
        return ConfigManager.get_variable_list();
    end
    
    def get_config_variable(args)
        arg_name = args["name"]
        return ConfigManager.get(arg_name);
    end

    def get_file_path(args)
        arg_name = args["name"]
        return ConfigManager.get(arg_name).gsub(/\\/, "/")
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return ["get_anji_list", "reload_anjis"]
    end

end