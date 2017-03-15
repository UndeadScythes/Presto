external_require "json"

# =============================================================================
# ConfigManager - Read and parses a JSON file containing parameters which can
# dictate the operation of software.
# =============================================================================
class ConfigManager

    # Set the default delimeter.
    @@DELIMETER = "."

    # Store the config file paths used to generate the current config state.
    @@CONFIG_FILE_PATHS = []

    @@ALTERNATE_CONFIG_PATHS_READ = []

    # Store the config settings that have been added.
    @@CONFIG = Hash.new

    # Create a new logger for this config manager.
    @@LOGGER = LogManager.get_logger("ConfigManager", nil, Logger::INFO)

    # -------------------------------------------------------------------------
    # Set a config key to a value, this will create the key if it does not
    # already exist.
    # -------------------------------------------------------------------------
    def self.set(key_path_string, value, hash = @@CONFIG)

        # First see if we have a final key, this would be a string with no
        # more delimeters in it.
        key_path = key_path_string.split(@@DELIMETER)
        if key_path.length == 1
            
            key_path = key_path[0]

            # We should get the current key and see if we need to merge keys.
            current_value = hash[key_path]

            if current_value == nil
                hash[key_path] = value
            
            # A value already exists for this key, if both the old and new 
            # values are hashes then we will need to merge.
            else

                if current_value.class == Hash && value == Hash

                    # Perform a set on each key in each the new hash adding new
                    # keys where necessary.
                    value.each do |sub_key, sub_value|
                        next_hash = hash[sub_key]
                        if next_hash == nil
                            next_hash = hash[sub_key] = Hash.new
                        end
                        self.set(sub_key, sub_value, next_hash)
                    end

                end

                if current_value.class == Array && value.class == Array

                    # Add the current array values to the new array.
                    value += current_value
                    value = value.uniq()

                end

                # We are not going to merge but perform an overwrite instead.
                # This action should be logged.
                @@LOGGER.debug("Overwriting a key: #{key_path} (#{current_value.length} -> #{value.length})")
                hash[key_path] = value

            end

        # If this is not the final key - we have more delimeters - then get the
        # next key and recurse.
        else

            next_key  = key_path[0]
            next_hash = hash[next_key]

            # If this is a new key then make sure we add a new hash here.
            if next_hash == nil
                hash[next_key] = Hash.new
            end

            # Rebuild the key path string and recurse.
            next_key_path_string = key_path[1..-1].join(@@DELIMETER)
            self.set(next_key_path_string, value, next_hash)

        end

    end

    # -------------------------------------------------------------------------
    # Read and parse the contents of all the stored config file.
    # -------------------------------------------------------------------------
    def self.add_config_file_path(config_file_path)
        @@CONFIG_FILE_PATHS << config_file_path
    end

    # -------------------------------------------------------------------------
    # Read and parse the contents of a config file.
    # -------------------------------------------------------------------------
    def self.read(config_file_path)

        # Parse the file and add the new config settings.
        begin
            config_file_contents = File.read(config_file_path)
            config = JSON.parse(config_file_contents)
            config.each do |key, value|
                self.set(key, value)
            end
        rescue => error
            @@LOGGER.error("Could not read config file #{config_file_path}: #{error}")
        end

        # Check if alternate config paths were provided.
        alternate_configs = self.get_array("alternate_config")
        if alternate_configs != nil

            @@LOGGER.info("Alternate config files found")

            # Load each of these configs.
            alternate_configs.each do |config_path|

                if @@ALTERNATE_CONFIG_PATHS_READ.include?(config_path)
                    next
                end
                @@ALTERNATE_CONFIG_PATHS_READ << config_path

                @@LOGGER.info("Reading alternate config file #{config_path}")

                # Set the path to root with presto.
                config_path = "#{config_path}"

                # Make sure we've not already loaded this file.
                if !@@CONFIG_FILE_PATHS.include?(config_path)
                    config_path = self.parse(config_path)
                    if File.exists?(config_path)
                        @@LOGGER.info("Reading config file #{config_path}")
                        self.read(config_path)
                    else
                        @@LOGGER.error("Alternate config file not found #{config_path}")
                    end
                end

            end

        end

    end

    # -------------------------------------------------------------------------
    # Read and parse the contents of all the stored config file.
    # -------------------------------------------------------------------------
    def self.read_all()
        @@LOGGER.info("Reading all config files")
        @@ALTERNATE_CONFIG_PATHS_READ.clear()
        @@CONFIG_FILE_PATHS.each do |config_file_path|
            @@LOGGER.info("Reading config file #{config_file_path}")
            self.read(self.parse(config_file_path))
        end
    end

    # -------------------------------------------------------------------------
    # Check if a key exists in the current config, returns true or false.
    # -------------------------------------------------------------------------
    def self.contains(key)
        return @@CONFIG[key] != nil
    end

    # -------------------------------------------------------------------------
    # Perform any key replacements that need to be done.
    # -------------------------------------------------------------------------
    def self.parse(value)
        if value != nil 
            value = value.dup
            if value.class == String
                presto_root = @@CONFIG["presto_root"]
                value.sub!("%PRESTO%", (presto_root == nil ? "" : presto_root))
            elsif value.class == Array
                array = value
                array.each do |array_value|
                    array_value = self.parse(array_value)
                end
                value = array
            end
        end
        return value
    end

    # -------------------------------------------------------------------------
    # Get the value of a key in the current config. Returns nil if the key has
    # not been set.
    # This method will also parse the value if required.
    # -------------------------------------------------------------------------
    def self.get(key)
        value = @@CONFIG[key]
        return self.parse(value)
    end

    # -------------------------------------------------------------------------
    # Delete an entry
    # -------------------------------------------------------------------------
    def self.delete(key)
        @@CONFIG.delete(key)
    end

    # -------------------------------------------------------------------------
    # Get the value of a key in the config as an array.
    # -------------------------------------------------------------------------
    def self.get_array(key)
        return self.get(key)
    end

    # -------------------------------------------------------------------------
    # Get the value of a key in the config as an int.
    # -------------------------------------------------------------------------
    def self.get_int(key)

        # Default the value to nil a then check the existence of the key.
        value = nil
        if self.contains(key)
            value = self.get(key).to_i
        end
        return value

    end
    
    def self.get_variable_list()
        variable_list = []
        
        @@CONFIG.each do |key, value|
            if value.class == String
                variable_list << "#{key}: #{value}"
            end
        end
        
        return variable_list
    end

    def self.get_root_config_file()
        return @@CONFIG_FILE_PATHS[0]
    end

    def self.get_presto_root()
        presto_root = self.get("presto_root")
        if presto_root != nil
            presto_root.gsub!(/\\/, "/")
        end
        return presto_root
    end

    def self.get_file_path(name)
        file_path = self.get(name)
        if file_path != nil
            file_path.gsub!(/\\/, "/")
        end
        return file_path

    end
end