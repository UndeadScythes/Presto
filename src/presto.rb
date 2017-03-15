# ==============================================================================
# Presto Web Server - This is the main file which will set up all the other
# parts of the webserver.
#
# This script takes the following command line options:
# -s, --silent  : Only logs FATAL errors.
# -q, --quiet   : Only logs ERROR and above errors.
# -v, --verbose : Logs INFO and above messages.
# -d, --debug   : Logs all messages.
#
# -c, --config-file : This is the path to the main server configuration JSON
#                     file. Ideally this should be an absolute path where
#                     possible.
#
# -r, --root : This is the path to the directory which contains the Presto web
#            : server files. Again, this should ideally be an absolute path.
#            : This is usually the folder where the default bat file is located.
# ==============================================================================

# Set a hard coded value for the current server version number.
$server_version = 1.1

# ------------------------------------------------------------------------------
# Wrap everything up so we can catch errors.
# ------------------------------------------------------------------------------
def run_server()

    # --------------------------------------------------------------------------
    # Create a function to require external libraries.
    # This allows us to disable the debugging for external libraries and retain
    # the debugging level after we have finished.
    # --------------------------------------------------------------------------
    def external_require(library_name)
        debug_level = $DEBUG
        $DEBUG = false
        require library_name
        $DEBUG = debug_level
    end

    # Load the LogManager file and create a root logger.
    require_relative "logger/LogManager"
    logger = LogManager.get_logger("PrestoWebServer", nil, Logger::INFO)
    logger.info("Starting Presto Web Server v#{$server_version}")

    # Load the ConfigManager file and build the command line option parser.
    require_relative "config/ConfigManager"
    external_require "optparse"
    option_parser = OptionParser.new do |options|

        # Generate the help text header.
        options.banner = "Usage: presto.rb [options]"

        # Check for verbose mode.
        options.on("-s", "--silent", "Perform no logging whatsoever") do
            LogManager.set_current_log_level(Logger::FATAL)
        end
        
        # Check for verbose mode.
        options.on("-q", "--quiet", "Log error messages only") do
            LogManager.set_current_log_level(Logger::ERROR)
        end

        # Check for verbose mode.
        options.on("-v", "--verbose", "Log information messages") do
            LogManager.set_current_log_level(Logger::INFO)
        end

        # Check for debug mode.
        options.on("-d", "--debug", "Log debug messages") do
            LogManager.set_current_log_level(Logger::DEBUG)
        end

        # Check for a config file.
        options.on("-c", "--config-file [file_path]", "Path to config file") do |config_file_path|
            ConfigManager.add_config_file_path(config_file_path)
        end

        # Check for a config file.
        options.on("-r", "--root [file_path]", "Path to Presto parent directory") do |presto_root|
            ConfigManager.set("presto_root", presto_root)
        end
    end

    # Now we need to check that we have a root folder specified.
    logger.info("Detecting root directory")
    presto_root = ConfigManager.get_presto_root()
    
    # If we have no presto root specified then use the current directory.
    if presto_root == nil
        presto_root = Dir.pwd()
        ConfigManager.set("presto_root", presto_root)
    end
    
    # Now that we definitely have a root directory add all our other folders
    # into the load path.
    logger.info("Adding subdirectories to load path")
    Dir.entries(presto_root).each do |directory_name|
        
        # Make sure we don't blindly add "." and ".." into our load path.
        if File.directory?(directory_name) and directory_name[/^\.{1,2}$/] == nil
            $LOAD_PATH << File.join(directory_name)
        end
    end

    # Parse the command line arguments and read the config files.
    logger.info("Reading command line options")
    option_parser.parse!
    ConfigManager.read_all()
    
    # Check to see if we have been given a log path.
    log_file_path = ConfigManager.get_file_path("log_file_path")
    if log_file_path != nil
        logger.info("Setting the log file path #{log_file_path}")
        LogOutput.set_log_file_path(log_file_path)
    end
    
    # Report the current default logging level.
    logger.info("Current default logging level: #{LogManager.get_default_log_level()}")

    # Load the ANJI manager file and load all the ANJIs.
    logger.info("Loading ANJI manager")
    require "AnjiManager"
    AnjiManager.load_all()

    # Load the user manager file, load any users found in config and then load
    # auth tokens from file.
    logger.info("Loading user manager")
    require "UserManager"
    UserManager.load_users_from_config()
    UserManager.read_auth_tokens_from_file()

    # Load the HTTP listener files and fire up the listeners.
    logger.info("Starting default listeners")
    require "HttpListener"
    http_listener  = Thread.new do
        HttpListener.new(ConfigManager.get_int("http_port"))
    end
    https_listener = Thread.new do
        HttpListener.new(ConfigManager.get_int("https_port"))
    end
    
    # Fire up listeners on other ports if required.
    alternate_ports = ConfigManager.get_array("alternate_ports")
    alternate_listeners = []
    if alternate_ports != nil
        logger.info("Starting alternate listeners")
        alternate_ports.each do |alternate_port|
                alternate_listeners << Thread.new do
                HttpListener.new(alternate_port)
            end
        end
    end

    # Wait for everything to finish up.
    logger.info("Waiting for all listeners to close")
    http_listener.join()
    https_listener.join()
    alternate_listeners.each do |alternate_listener|
        alternate_listener.join()
    end

    # Final log message to say that we are closing.
    logger.info("Good bye!")
    
end

# Run the server function and rescue all errors.
begin
    run_server()
rescue => error
    puts("#{"=" * 80}\nFATAL ERROR: #{error}\n#{"=" * 80}")
end