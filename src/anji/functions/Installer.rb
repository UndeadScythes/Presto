external_require "net/http"

# =============================================================================
# Installer - Install applications to the server.
# =============================================================================
class Installer < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Installer")

    # -------------------------------------------------------------------------
    # Install CodeMirror on this server.
    # -------------------------------------------------------------------------
    def install_codemirror()
        args = Hash.new
        args["name"]     = "install_code_mirror"
        args["cmd"]      = "run_python_script"
        args["threaded"] = "true"
        cm_modes = Editor.new.get_modes()
        mode_list = []
        cm_modes.each do |file_name, _, _|
            mode_list << file_name
        end
        args["args"]     = "\"#{ConfigManager.get("presto_root")}\" \"external\" \"#{ConfigManager.get("private_html_root")}/system\" \"support/nodejs\" \"#{mode_list.join(",")}\""
        @@LOGGER.debug("Running install script")
        do_nothing = Python.do_run_script("python/install_codemirror.py", true, args["args"])

        return "This done"
    end

    # -------------------------------------------------------------------------
    # Install Font Awesome on this server.
    # -------------------------------------------------------------------------
    def install_fontawesome()
        args = Hash.new
        args["name"]     = "install_fontawesome"
        args["cmd"]      = "run_python_script"
        args["threaded"] = "true"
        args["args"] = "\"#{ConfigManager.get("presto_root")}\" \"external\" \"#{ConfigManager.get("private_html_root")}/system\""
        @@LOGGER.debug("Running install script")
        do_nothing = Python.do_run_script("python/install_fontawesome.py", true, args["args"])

        return "This done"
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return ["install_codemirror", "install_fontawesome"]
    end

end