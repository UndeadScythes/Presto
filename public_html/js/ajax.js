// =============================================================================
// This file contains the Presto AJAX library.
// =============================================================================
function Ajax() {
    
    // -------------------------------------------------------------------------
    // A function which will try to parse a string to a JSON object.
    // If the object was not a valid JSON object then the string is returned.
    // -------------------------------------------------------------------------
    function try_to_parse_json(string) {
        try {
            string = JSON.parse(string);
        } catch(exception) {}
        return string;
    }
    
    // -------------------------------------------------------------------------
    // This function handles callbacks.
    // -------------------------------------------------------------------------
    function handle_callback(callback, callback_arguments) {
        
        // Check the callback function exists.
        if (callback !== undefined) {
        
            // Check we can call apply on the callback function.
            if (callback.apply === undefined) {
                throw "Callback function " + callback.toString() + " has no apply method";
            }

            // If we have no arguments then set them to be an empty array.
            if (callback_arguments === undefined) {
                callback_arguments = [];
            }

            // Apply the callback.
            callback.apply(window, callback_arguments);
        }
    }
    
    // -------------------------------------------------------------------------
    // Perform an AJAX request and pass the response back to a callback.
    // -------------------------------------------------------------------------
    this.call = function ajax___call(file_path, optional_callback, optional_callback_arguments) {
        
        // Build a new XHR object and set the ready state change event handler.
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                
                // Get the response and try to parse it.
                var response = try_to_parse_json(this.responseText);
                
                // Add the response to the callback arguments if we have any.
                var callback_arguments = [response];
                if (optional_callback_arguments !== undefined) {
                    callback_arguments.concat(optional_callback_arguments);
                }
                
                // Call the callback.
                handle_callback(optional_callback, callback_arguments);
            }
        };
        
        // Set the file path of the request and send it.
        xhr.open("GET", file_path, true);
        xhr.send();
    };

    // -------------------------------------------------------------------------
    // Load the result of an AJAX call into a DOM element.
    // -------------------------------------------------------------------------
    this.load = function ajax___load(dom_element, file_path, optional_callback, optional_callback_arguments) {
        
        // If we are loading the response into an iframe then just set the src
        // on the iframe instead.
        if (dom_element.nodeName.toLowerCase() === "iframe") {
            dom_element.src = file_path
            handle_callback(optional_callback, optional_callback_arguments);
            
        // Otherwise set up an AJAX call with a specific callback.
        } else {
            this.call(file_path, function(response) {
                dom_element.innerHTML = response;
                handle_callback(optional_callback, optional_callback_arguments);
            });
        }
    };
    
    // -------------------------------------------------------------------------
    // Send the results of an AJAX call into a native alert.
    // -------------------------------------------------------------------------
    this.alert = function ajax___alert(file_path, optional_callback, optional_callback_arguments) {
        this.call(file_path, function(response) {
            alert(response);
            handle_callback(optional_callback, optional_callback_arguments);
        });
    };
    
    // -------------------------------------------------------------------------
    // Similar to the alert function but instead the response will appear in a
    // UI status strip.
    // -------------------------------------------------------------------------
    this.status = function ajax___status(file_path, optional_timeout, optional_callback, optional_callback_arguments) {
        this.call(file_path, function(response) {
            ui.status(response, optional_timeout);
            handle_callback(optional_callback, optional_callback_arguments);
        });
    }
}

// Open up the public API.
var ajax = new Ajax();