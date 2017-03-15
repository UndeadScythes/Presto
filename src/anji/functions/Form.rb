# =============================================================================
# Form - Dynamically build forms from elements and tie them together with an 
# optional subit button.
# =============================================================================
class Form < Anji

	# Create a logger for this class.
	@@LOGGER = LogManager.get_logger("Form")

	# Store the current forms.
	@@current_forms = Hash.new

	# -------------------------------------------------------------------------
	# Create a text input.
	# -------------------------------------------------------------------------
	def create_text_input(args)

		# Get out input args.
		id             = args["id"]
		form           = args["form"]
		label          = args["label"] || ""
		focus          = is_true(args["focus"])
		submit_onenter = is_true(args["submit_onenter"])

		# If we are building a form then add the ID of this input.
		if form != nil 
			if @@current_forms[form] == nil
				@@current_forms[form] = []
			end
			@@current_forms[form] << id
		end

		# Build the optional additions.
		focus_script = (focus ? "<script>window.addEventListener('load', function() {document.getElementById('#{id}').focus();}, false);</script>" : "")
		onkeydown_script = (submit_onenter ? "<script>function key_down_#{id}(key_event) {if (key_event.keyCode == 13) {submit_form_#{form}();}}</script>" : "")
		onkeydown_attr   = (submit_onenter ? " onkeydown='key_down_#{id}(event);'" : "")
		
		# Return the complete HTML.
		return "#{focus_script}#{onkeydown_script}<label for='#{id}'>#{label}<input id='#{id}' type='text'#{onkeydown_attr}></label>"

	end

	# -------------------------------------------------------------------------
	# Create a password input.
	# -------------------------------------------------------------------------
	def create_password_input(args)

		# Get out input args.
		id             = args["id"]
		form           = args["form"]
		label          = args["label"] || ""
		focus          = is_true(args["focus"])
		submit_onenter = is_true(args["submit_onenter"])

		# If we are building a form then add the ID of this input.
		if form != nil 
			if @@current_forms[form] == nil
				@@current_forms[form] = []
			end
			@@current_forms[form] << id
		end

		# Build the optional additions.
		focus_script     = (focus ? "<script>window.addEventListener('load', function() {document.getElementById('#{id}').focus();}, false);</script>" : "")
		onkeydown_script = (submit_onenter ? "<script>function key_down_#{id}(key_event) {if (key_event.keyCode == 13) {submit_form_#{form}();}}</script>" : "")
		onkeydown_attr   = (submit_onenter ? " onkeydown='key_down_#{id}(event);'" : "")

		# Return the complete HTML.
		return "#{focus_script}#{onkeydown_script}<label for='#{id}'>#{label}<input id='#{id}' type='password'#{onkeydown_attr}></label>"

	end

	# -------------------------------------------------------------------------
	# Create a submit button which will tie together any other elements in the
	# same form.
	# -------------------------------------------------------------------------
	def create_submit_button(args)

		form = args["form"]
		destination = args["destination"]
		text = args["text"] || "Submit"

		form_ids = @@current_forms[form]
		submit_script = ""
		if form_ids
			submit_script = "<script>function submit_form_#{form}() {var form_args = "
			form_args = []
			@@current_forms[form].each do |id|
				form_args << "'#{id}=' + encodeURIComponent(document.getElementById('#{id}').value)"
			end
			@@current_forms.delete(form)
			submit_script += "#{form_args.join(" + '&' + ")};"
			submit_script += "location.href = '#{destination}?' + form_args;}</script>"
		end
		return "#{submit_script}<button onclick='submit_form_#{form}();'>#{text}</button>"
	end

	# -------------------------------------------------------------------------
	# Create a hidden input.
	# -------------------------------------------------------------------------
	def create_hidden_input(args)
		id = args["id"]
		form = args["form"]
		value = args["value"]

		if @@current_forms[form] == nil
			@@current_forms[form] = []
		end

		@@current_forms[form] << id
		return "<input id='#{id}' type='hidden' value='#{value}'>"
	end

	# -------------------------------------------------------------------------
	# Return the function this ANJI provides.
	# -------------------------------------------------------------------------
	def self.get_names()
		return []
	end

end