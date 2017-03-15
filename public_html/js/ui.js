// =============================================================================
// UI - Handle the creation of new UI elements.
// =============================================================================
function UI() {
    
    // Keep a record of each modal div.
    var modal_divs = {};
    
    // -------------------------------------------------------------------------
    // Close an opened modal div.
    // -------------------------------------------------------------------------
    function close_modal_div(id) {
        
        // Get the modal div and check it exists.
        var modal_div = modal_divs[id];
        if (modal_div === undefined) {
            throw "No modal div with id [" + id + "] exists";
        }
        
        // Remove the modal div from the page.
        presto.remove(modal_div);
        
        // Delete the record from our list.
        delete modal_divs[id];
    }
    
    // -------------------------------------------------------------------------
    // This function adds the close frame function to an iframe on load.
    // -------------------------------------------------------------------------
    function add_close_api(iframe, id) {
        iframe.contentWindow.ui = {
            close_modal_div : close_modal_div.bind(window, id)
        };
    }
    
    // -------------------------------------------------------------------------
    // Open a new modal div on the screen.
    // -------------------------------------------------------------------------
    this.open_modal_div = function ui___open_modal_div(id, url) {
        
        // Check we aren't overwriting an old div.
        if (modal_divs[id] !== undefined) {
            throw "A modal div with id [" + id + "] already exists";
        }
        
        // Create the div, set styles and add class names.
        var modal_div = presto.new("div");
        modal_div.id = "modal_div_" + id;
        modal_div.style.zIndex = 1000;
        modal_div.className = "modal_div";
        
        // Create the container div that will hold the content.
        var container_div = presto.new("div");
        modal_div.appendChild(container_div);
        
        // Create an iframe to sit inside the modal div which will contain the
        // content.
        var iframe = presto.new("iframe");
        iframe.style.width  = "100%";
        iframe.style.height = "100%";
        container_div.appendChild(iframe);
        
        // Add the modal div to the page and then load the iframe.
        presto.add(modal_div);
        iframe.src = url;
        
        // Add an onload to the iframe to set the close function.
        iframe.onload = add_close_api.bind(window, iframe, id);
        
        // Add the div to the list.
        modal_divs[id] = modal_div;
    }
    
    // Keep a reference to the status strips.
    var status_container;
    var status_strips = {};
    
    // -------------------------------------------------------------------------
    // Build the status strip container and add it to the page.
    // -------------------------------------------------------------------------
    function add_status_container() {
        
        // Build the container.
        status_container = presto.new("div");
        status_container.style.position = "absolute";
        status_container.style.display = "inline-block";
        status_container.style.top = "0";
        status_container.style.height = "auto";
        status_container.style.right = "0";
        status_container.style.zIndex = "1000";
        
        // Add the container to the page.
        presto.add(status_container);
    }
    
    // -------------------------------------------------------------------------
    // Build a new status strip.
    // -------------------------------------------------------------------------
    function build_status(message) {
        
        // Get a timestamp ID for this status strip.
        var id = presto.id("status_strip");
        
        // Build the div, style it and set the text.
        var message_div = presto.new("span");
        message_div.innerHTML = message;
        message_div.style.background = "white";
        message_div.style.border = "2px solid black";
        message_div.onclick = ui.remove_status.bind(window, id);
        message_div.style.cursor = "pointer";
        message_div.style.display = "inline-block";
        var status_strip = presto.new("div");
        status_strip.style.zIndex = "500";
        status_strip.appendChild(message_div);
        
        // Add the status strip to the page and return the ID.
        status_container.appendChild(status_strip);
        status_strips[id] = status_strip;
        return id;
    }
    
    // -------------------------------------------------------------------------
    // Remove the status strip.
    // -------------------------------------------------------------------------
    this.remove_status = function ui___remove_status(id) {
        
        // Get the status strip.
        var status_strip = status_strips[id];
        
        // Check the strip still exists.
        if (status_strip !== undefined) {
        
            // Remove the strip from the page.
            status_container.removeChild(status_strip);
        }
        
        // Remove the status strip from the list.
        delete status_strips[id];
    }
    
    // -------------------------------------------------------------------------
    // Add a small status strip to the page.
    // -------------------------------------------------------------------------
    this.status = function ui___status(message, optional_timeout) {
        
        // Check if the container has been built yet.
        if (status_container === undefined) {
            add_status_container();
        }
        
        var id;
        
        // If a message has been passed then build a new status.
        if (message !== undefined && message.replace(/[\r\n]/g, "") !== "") {
        
            // Remove trailing new lines.
            message = message.replace(/[\r\n]+$/, "");
            
            // Replace new lines with "<br>" tags.
            message = message.replace(/\r?\n/g, "<br>");
            
            // Add the strip to our list.
            id = build_status(message);

            // Handle the timeout.
            if (optional_timeout !== undefined && isNaN(optional_timeout) === false) {
                status_timeout = setTimeout(ui.remove_status.bind(window, id), optional_timeout);
            }
        }
        
        // Return the ID.
        return id;
    }
    
    // -------------------------------------------------------------------------
    // This function forces sticky elements to the correct sizes.
    // -------------------------------------------------------------------------
    this.stick = function ui___stick(element) {
        
        // Get the elements either side of this one.
        var previous_element = element.previousElementSibling;
        var next_element     = element.nextElementSibling;
        
        // Set the top and bottom of the element.
        element.style.position = "absolute";
        if (previous_element !== undefined && next_element !== undefined) {
            var previous_bottom = previous_element.getBoundingClientRect().bottom;
            var next_top        = next_element.getBoundingClientRect().top;
            element.style.top    = previous_bottom + "px";
            element.style.height = (next_top - previous_bottom) + "px";
        } else {
            element.style.top    = "";
            element.style.height = "";
        }
    }
}

// Open up the public API.
var ui = new UI();