# We need a JSON builder here.
require "json"

# ==============================================================================
# Editor - Build HTML elements and structures.
# ==============================================================================
class Editor < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Editor")

    # --------------------------------------------------------------------------
    # Link all the CodeMirror files in the codemirror directory.
    # --------------------------------------------------------------------------
    def link_codemirror_files()
        
        # Build the codemirror directory.
        codemirror_directory = "#{ConfigManager.get("private_html_root")}/system/codemirror".gsub(/\\/, "/")
        @@LOGGER.info("CodeMirror directory #{codemirror_directory}")
        
        # Get a list of the JS and CSS files in this folder.
        js_file_list  = Dir["#{codemirror_directory}/*.js" ]
        css_file_list = Dir["#{codemirror_directory}/*.css"]
        @@LOGGER.info("Found #{js_file_list.length + css_file_list.length} files")
        
        # Loop over each list adding the linked result to the response.
        response = ""
        js_file_list.each do |js_file_name|
            js_file_name.sub!(/^#{ConfigManager.get_file_path("private_html_root")}/, "")
            response += Link.link_js(js_file_name)
        end
        css_file_list.each do |css_file_name|
            css_file_name.sub!(/^#{ConfigManager.get_file_path("private_html_root")}/, "")
            response += Link.link_css(css_file_name)
        end
        
        # Return the response.
        return response
        
    end

    def self.build_file_list(file_path)

        # Build the file list.
        file_list = ["<ul>"]
        Dir.entries(file_path).each do |file_name|

            # For each entry do something slightly different for files and directories.
            if File.directory?(File.join(file_path, file_name))
                file_list << "<li class='dir'><span class='link' onclick='open_file(\"#{file_name}\");'>#{file_name}/</span></li>\n"
            else
                file_list << "<li class='file'><span class='link' onclick='open_file(\"#{file_name}\");'>#{file_name}</span></li>\n"
            end

        end

        file_list << "</ul>"

        return file_list.join("")
    end

    def build_file_list(arguments)
        file_path = arguments["file_path"] || ConfigManager.get("presto_root")
        return Editor.build_file_list(file_path)
    end
    
    # --------------------------------------------------------------------------
    # Embed an HTML snippet.
    # --------------------------------------------------------------------------
    def file_path_request(arguments)

        # Parse the arguments.
        file_path = arguments["file_path"]
        file_parts = file_path.split("/")
        @@LOGGER.debug("Got file path request for #{file_path}")

        # Build the response based upon the file type.
        response = Hash.new
        if File.exist?(file_path)

            if File.directory?(file_path)

                @@LOGGER.debug("It was a directory")

                # Build the response parts.
                response["type"]      = "directory"
                response["content"]   = Editor.build_file_list(file_path)
                response["directory"] = file_path

            else

                @@LOGGER.debug("It was a file")

                # Build the response parts.
                response["type"]      = "file"
                response["content"]   = File.read(file_path)
                response["file_name"] = file_parts[-1]
                response["directory"] = File.join(file_parts[0..-2])

            end

        else

            # If the file does not exist return an error.
            response["type"]    = "error"
            response["message"] = "#{file_path} does not exist"

        end

        # Generate a JSON string and return a response.
        @@LOGGER.debug("Will now try to make a JSON string from #{response}")
        response = JSON.generate(response)
        return response
    end

    def get_modes()

        modes = [
            ["ruby",       "rb",   "text/x-ruby"    ],
            ["css",        "css",  "text/css"       ],
            ["xml",        "xml",  "text/xml"       ],
            ["htmlmixed",  "html", "text/html"      ],
            ["javascript", "js",   "text/javascript"],
            ["python",     "py",   "text/x-python"  ],
            ["sql",        "sql",  "text/x-sql"     ]
        ]

        return modes

    end

    # --------------------------------------------------------------------------
    # Save the file contents to the file path specified.
    # --------------------------------------------------------------------------
    def file_save(options)
        
        # Get the file path and content.
        file_path    = options["file_path"]
        file_content = options["file_content"]

        # Get the file name and set the default response.
        file_name = file_path.split(/\/|\\/)[-1]
        response = "#{file_name} saved"
        
        # Open the file and write the contents.
        begin
            File.open(file_path, "w") do |file|
                file.write(file_content)
            end
        rescue => error
            response = error
        end

        return response
    end
  
    def link_mode_js_files()
        modes = get_modes()
      
        response = ""
        
        modes.each do |file_name, _, _|
            options = Hash.new
            options["file"] = "/system/codemirror/modes/#{file_name}.js"
            response += Link.new.link_js(options)
        end
      
        return response
    end
  
    def get_mode_map()
        
        modes = get_modes()
      
        response = "var mode_map = {"
        
        mode_map = []
      
        modes.each do |_, extension, mime_type|
            mode_map << "'#{extension}' : '#{mime_type}'"
        end
      
        return "#{response}#{mode_map.join(",")}};"

    end
    
    def delete_file(options)
        file_path  = options["file_path"]
        file_parts = file_path.split("/")
        file_name  = file_parts[-1]
        @@LOGGER.debug("Deleting #{file_name}")
        system("del #{file_path.gsub(/\//, "\\")}")
        options["file_path"] = File.join(file_parts[0..-2])
        return file_path_request(options)
    end

    def new_file(options)
        file_name    = options["file_name"]
        current_path = options["current_path"]
        options["file_path"] = current_path
        system("copy NUL > #{current_path}\\#{file_name.gsub(/\//, "\\")}")
        return file_path_request(options)
    end
        
    
    # --------------------------------------------------------------------------
    # Build an object which represents a rule.
    # The arguments are treated as follows:
    #     file_type : This is the file type, pass a CSV of file extensions to
    #                 which this rule should apply.
    #     regex     : A regex which will trigger the rule when it finds a match.
    #     message   : The message wich should be displayed in the editor.
    #     type      : One of "style", "warning" or "error".
    #     reason    : The hoverover of the error which is best used to describe
    #                 the reason for the rule.
    #     fix       : A sed style string which can be used to fix all cases of
    #                 this error.
    # --------------------------------------------------------------------------
    def build_rule(file_type, regex, message, type = "error", reason = "", fix = "")
        rule = Hash.new
        rule["file_type"] = file_type
        # This is quite possibly the WORST regex I've ever had to write.
        rule["regex"]     = regex.gsub!(/\\/, "\\" * 8)
        rule["message"]   = message
        rule["type"]      = type
        rule["reason"]    = reason
        rule["fix"]       = fix
        return rule
    end
        
    # --------------------------------------------------------------------------
    # Go through the list of rules and create an array which we can turn into a
    # JSON string.
    # --------------------------------------------------------------------------
    def get_bug_check_rules()
        bug_check_rules = []
        bug_check_rules << build_rule("py", "['\\\"]\\s\\+|\\+\\s['\\\"]",         "Use .format instead of +")
        bug_check_rules << build_rule("rb", "\\+\\s*[#'\\\"]\\|\\[}'\\\"]\\s*\\+", "Use File.join")
        bug_check_rules << build_rule("",   "\\t",                                 "Tab character found")
        bug_check_rules << build_rule("",   "\\b(dir|args?)\\b",                   "Found abbreviation - %capture%",                     "warning")
        bug_check_rules << build_rule("",   "^(?:\\s{4})*\\s{1,3}\\S",             "Irregular indentation")
        bug_check_rules << build_rule("",   "\\S\\s+$",                            "Trailing whitespace")
        bug_check_rules << build_rule("rb", "\\/\.match\\s*\\(",                   "Use string[/regex/] instead of string.match(regex)")
        bug_check_rules << build_rule("rb", "ConfigManager\\.get\\s*\\(",          "Use a specific config value getter if you can",      "warning")
        return JSON.generate(bug_check_rules)
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return ["file_path_request", "file_save", "delete_file", "new_file"]
    end

end