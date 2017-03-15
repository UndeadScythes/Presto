# =============================================================================
# User - Description.
# =============================================================================
class User < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("User")

	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def logout(args)
		UserManager.logout(args)
		headers = Http.set_cookie("auth_token", "")
		return Http.get_redirect("/", headers)
	end

	# -------------------------------------------------------------------------
	# Perform a task.
	# -------------------------------------------------------------------------
	def create_logout_button(args)
        html = "<script>function logout() {location.href='/anji?cmd=logout';}</script><button onclick='logout();'>Logout</button>"
        if is_true(args["use_fa"])
            html = "<script>function logout() {location.href='/anji?cmd=logout';}</script><button onclick='logout();' class='fa fa-sign-out'></button>"
        end
        return html
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return ["logout"]
	end

end