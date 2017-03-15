# Include a URL decoder.
external_require("cgi")

# =============================================================================
# Http - Do HTTP stuff - the protocol stuff.
# =============================================================================
class Http

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Http")

    # Set the default communication terminator.
    @@TERMINATOR = "\n\n"

    # Set the HTTP protocol string.
    @@PROTOCOL = "HTTP/1.1"

    # -------------------------------------------------------------------------
    # Parse a query string into a has map.
    # -------------------------------------------------------------------------
    def self.parse_query_string(full_query_string)

        query_string_arguments = Hash.new
        
        # Check if we have a query string at all.
        if full_query_string != nil

            @@LOGGER.debug("Found query string: '#{full_query_string}'")

            # Split the query string into sub strings.
            query_strings = full_query_string.split("&")

            # Parse each individual query string.
            query_strings.each do |query_string|

                # Split the string into key value pairs and decode the value.
                key, value = query_string.split("=")
                value = CGI.unescape(value)
                @@LOGGER.debug("Adding query string arg: '#{key}'->'#{value}'")

                # Add the query string pair.
                query_string_arguments[key] = value

            end

        end

        return query_string_arguments

    end

    # -------------------------------------------------------------------------
    # Parse cookies out of a header request.
    # -------------------------------------------------------------------------
    def self.parse_cookies(full_request)

        full_cookie_string = full_request.match(/^Cookie: (.*)$/)
        cookies = Hash.new
        if full_cookie_string != nil
            cookie_strings = full_cookie_string.captures[0].split(/; */)
            cookie_strings.each do |cookie_string|
                cookie_string.gsub!(/[\r\n] $/, "")
                cookie_key, cookie_value = cookie_string.split("=", 2)
                @@LOGGER.debug("Recording cookie #{cookie_key} -> #{cookie_value}")
                cookies[cookie_key] = cookie_value
            end
        end

        return cookies
    end

    # -------------------------------------------------------------------------
    # Parse a request and serve a response.
    # -------------------------------------------------------------------------
    def self.get_error(error_code)

        response = ""
        case error_code
            when 400
                response = "400 Bad Request"
            when 401
                response = "401 Unauthorized"
            when 404
                response = "404 Not Found"
            else
                @@LOGGER.error("Unknown error code #{error_code}")
        end

        return "#{@@PROTOCOL} #{response}#{@@TERMINATOR}#{response}"

    end

    def self.get_success(success_code)

        response = ""
        case success_code
            when 200
                response = "HTTP/1.1 200 OK"
            else
                @@LOGGER.error("Unknown success code #{success_code}")
        end

        return response
    end

    def self.set_cookie(cookie_name, cookie_value)
        return "Set-Cookie: #{cookie_name}=#{cookie_value}"
    end

    def self.get_redirect(file_path, headers = "")
        @@LOGGER.debug("Building redirect to #{file_path}")
        if headers != "" && !headers[/\n$/]
            @@LOGGER.warn("Headers passed to redirect request without trailing new line")
            headers = "#{headers}\n"
        end
        redirect_response = "HTTP/1.1 302 Redirection\n#{headers}Location: #{file_path}#{@@TERMINATOR}"
        @@LOGGER.debug("Built redirect response:\n#{redirect_response}")
        return redirect_response
    end

end