# Include our user manager.
require "UserManager"

# =============================================================================
# ServeRequest - Parse a client request and serve a response.
# =============================================================================
class ServeRequest

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("ServeRequest")

    # Set the default communication terminator.
    @@TERMINATOR = "\n\n"

    # -------------------------------------------------------------------------
    # Parse a request and serve a response.
    # -------------------------------------------------------------------------
    def self.parse(client, request)
        @@LOGGER.debug("Parsing request:\n#{request}")

        # See if we can find a request string.
        request_string = /^GET (.*?) HTTP\/[\d.]+\r?\n/i.match(request)
        if request_string == nil

            # Deliver an error page.
            response = Http.get_error(400)

        # Determine the correct response to the request.
        else
            request_string = request_string[1]
            response = self.serve_get(request_string, request)
        end

        begin
            client.puts(response)
        rescue => error
            @@LOGGER.error("Broken pipe: #{error}")
        end

    end

    # -------------------------------------------------------------------------
    # Detect the content type based upon the file path and name.
    # -------------------------------------------------------------------------
    def self.get_content_type(file_path)

        # Try to get the extension.
        extension_match = file_path.match(/\.(.*)$/)
        extension = (extension_match ? extension_match.captures[0] : "")
        
        # Set the type based on the extension.
        content_type = ""
        case extension
            when "css"
                content_type = "text/css"
            when "html"
                content_type = "text/html"
            when "js"
                content_type = "text/javascript"
            else
                content_type = "application/data"
        end

        # Return our findings.
        return content_type

    end

    def self.serve_file(request_file_path, request_properties)

        @@LOGGER.debug("Serving file #{request_file_path}")
        
        symlinks = ConfigManager.get_array("symlinks")
        if symlinks != nil
            symlinks.each do |from, to|
                from = from.sub(/%PRESTO%/, ConfigManager.get_presto_root())
                to   = to.sub(/%PRESTO%/, ConfigManager.get_presto_root())
                @@LOGGER.debug("Checking for symlink #{from} -> #{to}")
                request_file_path.sub!(/^#{from}/, to)
            end
        end
        
        @@LOGGER.debug("File path after following symlinks: #{request_file_path}")

        # Check if this is a directory.
        if File.directory?(request_file_path)
            request_file_path = (request_file_path[/\/$/] ? "#{request_file_path}index.html" : "#{request_file_path}/index.html")
            @@LOGGER.debug("Found directory, changed request to #{request_file_path}")
        end

        # Check the file exists.
        if File.exist?(request_file_path) || File.symlink?(request_file_path)

            # Deliver the file content
            @@LOGGER.debug("File found: #{request_file_path}")
            content_type = self.get_content_type(request_file_path)
            @@LOGGER.debug("Content type of #{request_file_path} detected as #{content_type}")
            response = "#{Http.get_success(200)}\nContent-Type: #{content_type}#{@@TERMINATOR}"
            requested_file = File.open(request_file_path, "rb")
            response += requested_file.read
            requested_file.close

            # Parse any ANJIs in the file.
            response = AnjiManager.parse(response, request_properties)

        else

            # Return ye olde 404.
            @@LOGGER.debug("File not found: #{request_file_path}")
            response = Http.get_error(404)

        end

        return response

    end

    def self.serve_public_file(request_string, request_properties)
        public_html_root = ConfigManager.get_file_path("public_html_root")
        request_file_path = "#{public_html_root}#{request_string}"
        return self.serve_file(request_file_path, request_properties)
    end

    def self.serve_private_file(request_string, request_properties)
        private_html_root = ConfigManager.get_file_path("private_html_root")
        request_file_path = "#{private_html_root}#{request_string}"
        return self.serve_file(request_file_path, request_properties)
    end

    # -------------------------------------------------------------------------
    # Decide how to serve the request.
    # -------------------------------------------------------------------------
    def self.serve_get(request_string, full_request)

        # Log that we are serving a request and put a nice line of "=" in there.
        @@LOGGER.info("Serving request: #{request_string.sub(/\n*$/, "")}")

        # Split the request apart from any query string.
        request_split = request_string.split("?", 2)
        request_string = request_split[0]

        # If there is a query string then parse it.
        query_string_arguments = Http.parse_query_string(request_split[1])

        # Get any cookies that have been set.
        cookies = Http.parse_cookies(full_request)

        # Replace all the slashes.
        request_string.sub!("\\", "/")

        # Force a slash at the start of the string.
        if !request_string[/^\//]
            request_string = "/#{request_string}"
        end

        response = ""
        query_string_arguments["request_string"] = request_string

        # Check if the user wants to invoke an ANJI or login.
        if request_string == "/anji"
            @@LOGGER.debug("Invoking ANJI")
            anji_name = query_string_arguments["cmd"]
            response = AnjiManager.invoke(anji_name, query_string_arguments)
        elsif request_string == "/login"
            @@LOGGER.debug("Attempting a login")
            begin
                response = UserManager.login(query_string_arguments)
            rescue NoUserException, PasswordMismatchException
                @@LOGGER.debug("Failed to log user in")
                referer = "/#{query_string_arguments["referer"] || "index.html"}"
                @@LOGGER.debug("Referer set to #{referer}")
                auth_token_reset = Http.set_cookie("auth_token", "")
                response = Http.get_redirect("#{referer}?response=Invalid username or password", auth_token_reset)
                @@LOGGER.debug("Sending response: #{response}")
            end
        else

            # Try to serve a file.
            @@LOGGER.debug("File request detected: #{request_string}")
            valid_auth_token = UserManager.check_auth_token(cookies)
            if valid_auth_token
                if UserManager.has_access(UserManager.get_username_from_auth_token(cookies["auth_token"]), request_string)
                    response = self.serve_private_file(request_string, query_string_arguments)
                else
                    response = Http.get_error(401)
                end
            else
                response = self.serve_public_file(request_string, query_string_arguments)
            end

        end

        return response

    end

end