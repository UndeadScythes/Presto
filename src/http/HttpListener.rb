external_require "socket"
require "ServeRequest"

# =============================================================================
# HttpListener - Listen for connections and spawn new threads to handle each
# request received.
# =============================================================================
class HttpListener

	# -------------------------------------------------------------------------
	# Intialise the listener on the specified port.
	# -------------------------------------------------------------------------
	def initialize(port)

		# Create a new logger.
		@LOGGER = LogManager.get_logger("HttpListener#{port}")

		# Check we have a port.
		if port == nil
			@LOGGER.warn("No port provided to HttpListener")
			return
		end

		# Set up the listener.
		server = TCPServer.new(port)
		@LOGGER.info("Listening on port #{port}")
		listen(server)		

	end

	# -------------------------------------------------------------------------
	# Start listening.
	# -------------------------------------------------------------------------
	def listen(server)

		# Start a loop listening for incoming message.
		loop do

			# Start a new thread on each connection accept.
			Thread.start(server.accept) do |client|

				# Get some details from the client.
				_, _, _, remote_ip = client.peeraddr
				@LOGGER.info("Connection received from #{remote_ip}")

				# Loop until we get a blank line.
				request = ""
				while line = client.gets
					@LOGGER.debug("Got line: #{line.gsub(/[\r\n]+/, "")}")
					if line == "\r\n"
						break
					end
					request += line
				end

				# Serve the request and close the client.
				ServeRequest.parse(client, request.sub(/\r\n$/, ""))
				client.close
				@LOGGER.debug("Connection closed")

			end

		end

	end

end