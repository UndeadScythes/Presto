// =============================================================================
// This is the main file editor JS file which handles lots of things.
// =============================================================================

// Store the currently opened file's name, extension and directory.
var current_file_name = "<ANJI Environment.get_query_string_arg({"name":"file_name"})/>";
var current_file_extension = current_file_name.replace(/^[^.]*\./, "");
var current_directory = "<ANJI Environment.get_query_string_arg({"name":"directory"})/>";

// Store the currently slected directory.
var selected_directory = "<ANJI Files.get_presto_root()/>";

// Store the state of the control panel.
var control_panel_open = false;

// A global variable which points to the CodeMirror object.
var editor;

// Store the current editor mode.
var editor_mode = "file";

// -----------------------------------------------------------------------------
// Get the current file path.
// -----------------------------------------------------------------------------
function get_current_file_path() {
    return current_directory + "/" + current_file_name;
}

// -----------------------------------------------------------------------------
// Set the selected directory.
// -----------------------------------------------------------------------------
function set_selected_directory(new_selected_directory) {

    // Set the selected directory.
    selected_directory = new_selected_directory;
    
    // Remove all instances of "/directory/..".
    selected_directory = selected_directory.replace(/\/[^\/]+\/\.\./, "");
    
    // Remove all instances of "/.".
    selected_directory = selected_directory.replace(/\/\./, "");
    
    // Display the selected directory.
    presto.get("selected_directory").innerText = selected_directory;
}

// -----------------------------------------------------------------------------
// Open and close the control panel.
// -----------------------------------------------------------------------------
function toggle_control_panel() {
    if (control_panel_open === true) {
        presto.get("control_panel").style.width = "20px";
        presto.get("editor_container").style.left = "20px";
        presto.get("control_panel_handle").firstElementChild.className = "fa fa-angle-double-right";
    } else {
        presto.get("control_panel").style.width = "250px";
        presto.get("editor_container").style.left = "250px";
        presto.get("control_panel_handle").firstElementChild.className = "fa fa-angle-double-left";
    }
    control_panel_open = !control_panel_open;
}

// -----------------------------------------------------------------------------
// A function which inserts up to 80 characters of dashes to surround comment
// headers.
// -----------------------------------------------------------------------------
function insert_comment_line() {
    
    // Get the current line number, char number and then the line content.
    line_number = editor.getCursor().line;
    char_number = editor.getCursor().ch;
    line_content = editor.getLine(line_number);
    
    // If we have a full line already and it is mostly dashes then we will
    // replace the line with equals.
    if (line_content.length === 80 && /-+$/.test(line_content) === true) {
        
        line_content = line_content.split(" ");
        var dashes = line_content[line_content.length - 1];
        line_content = line_content.slice(0, -1).concat([dashes.replace(/\-/g, "=")]);
        line_content = line_content.join(" ");
        editor.replaceRange(line_content, {
            line : line_number,
            ch   : 0
        }, {
            line : line_number,
            ch   : 80
        });
        
    } else {

        // Build up the comment line.
        comment_line = "";
        switch (current_file_extension) {
            case "js":
                comment_line = "// ";
                break;
            case "py":
            case "rb":
                comment_line = "# ";
                break;
        }
        comment_line += Array(80 - line_content.length - comment_line.length).fill("-").join("");

        // Put that text in position.
        editor.replaceRange(comment_line, {
            line : line_number,
            ch   : char_number
        });
    }
}

// -----------------------------------------------------------------------------
// Load the file editor into the page.
// -----------------------------------------------------------------------------
function load_editor() {
    
    // Get the textarea where we will load the file editor.
    var editor_textarea = presto.get("editor_textarea");
    
    // If we don't have Code Mirror then just open the control panel.
    if (CodeMirror === undefined) {
        editor_textarea.nodeName = "div";
        editor_textarea.innerHTML = "This server does not yet have Code Mirror installed on it";

    } else {
    
        // Create a new instance of CodeMirror.
        editor = CodeMirror.fromTextArea(editor_textarea, {
            lineNumbers : true,
            indentUnit  : 4,
            rulers      : [80]
        });

        // Set the size of the editor and set some hotkeys.
        editor.setSize("100%", "100%");
        editor.setOption("extraKeys", {
            "Ctrl-B" : bug_check,
            "Ctrl-S" : save,
            "Ctrl-/" : insert_comment_line,
            "Tab"    : function(cm) {
                var spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
                cm.replaceSelection(spaces);
            }
        });
    }
    
    // If we don't have a file name then open the control panel.
    if (current_file_name === "") {
        toggle_control_panel();
    } else {
        toggle_control_panel();
        open_file_path(current_directory + "/" + current_file_name);
        open_file_path(current_directory);
    }
}

// -----------------------------------------------------------------------------
// Get the map of extensions to mode names and build a function to get a mode
// from a file name.
// -----------------------------------------------------------------------------
<ANJI Editor.get_mode_map()/>
function get_mode(file_name) {
    extension = /\..*$/.exec(file_name);
    if (extension === null) {
        return "text/text";
    }
    extension = extension[0];
    extension = extension.substring(1);
    mode = mode_map[extension];
    return (mode !== undefined ? mode : "text/text");
}

function update_file_list(file_list) {
    presto.get("file_list").innerHTML = file_list;
}

function set_current_file(directory, file_name) {
    current_directory = directory;
    current_file_name = file_name;
    presto.get("current_file_name").innerText = current_file_name;
    current_file_extension = current_file_name.replace(/^[^.]*\./, "");
    window.history.replaceState(undefined, undefined, "/editor/editor.html?directory=" + current_directory + "&file_name=" + current_file_name);
}

// -----------------------------------------------------------------------------
// Update the control panel, this include the file details and the file list.
// -----------------------------------------------------------------------------
function update_control_panel(response) {
    
    // Detect what type of update this is.
    switch (response.type) {
            
        // A directory update.
        case "directory":
            
            // Update the file list and the selected directory.
            update_file_list(response.content);
            set_selected_directory(response.directory);
            break
    
        // A file update.
        case "file":
        
            // Set the editor content and set focus.
            editor.setValue(response.content);
            editor.focus();
            
            // Update the current file and set the mode.
            var file_name = response.file_name;
            editor.setOption("mode", get_mode(file_name));
            set_current_file(response.directory, file_name);
            toggle_control_panel();
            break;
            
        // An error.
        case "error":
            ui.status(response.message);
            break;
    }
}

function open_file(file_name) {
    ajax.call("/anji?cmd=file_path_request&file_path=" + selected_directory + "/" + file_name, update_control_panel);
}

function open_file_path(file_path) {
    ajax.call("/anji?cmd=file_path_request&file_path=" + file_path, update_control_panel);
}

function save_file() {
    bug_check()
    var file_content = editor.getValue();
    var file_path = current_directory + "/" + current_file_name;
    ajax.status("/anji?cmd=file_save&file_path=" + file_path + "&current_path=" + current_directory + "&file_content=" + encodeURIComponent(file_content), 1000);
}
    
function open_console() {
    ui.open_modal_div("console", "/console");
}
    
function load_codemirror() {
    ajax.status("/anji?cmd=install_code_mirror");
}

function delete_file() {
    ajax.call("/anji?cmd=delete_file&file_path=" + get_current_file_path(), update_control_panel);
}

// -----------------------------------------------------------------------------
// Create a new empty file in the currently selected directory.
// -----------------------------------------------------------------------------
function new_file() {
    ajax.call(presto.anji("new_file", {
        file_name    : prompt("New file name:"),
        current_path : selected_directory
    }), update_control_panel);
}

// Store the currently displayed widgets.
var widgets = [];

// Store the ID of the last bug status strip.
var status_id;

// -----------------------------------------------------------------------------
// Create a widget to display a discovered bug.
// -----------------------------------------------------------------------------
function add_widget(line_number, message, color) {
    
    // Create the div, style it, add the message and return it.
    var widget = presto.new("div");
    var icon   = presto.new("span");
    icon.className = "fa fa-exclamation-circle";
    icon.style.marginRight = "5px";
    icon.style.marginLeft = "5px";
    widget.style.color = color;
    widget.appendChild(icon);
    widget.appendChild(presto.new_text(message));
    widgets.push(editor.addLineWidget(line_number, widget));
}

// Create different types of widgets with different colors.
function add_style(line_number, message) {
    return add_widget(line_number, message, "green");
}
function add_warning(line_number, message) {
    return add_widget(line_number, message, "orange");
}
function add_error(line_number, message) {
    return add_widget(line_number, message, "red");
}

// -----------------------------------------------------------------------------
// Check the current file for bugs.
// -----------------------------------------------------------------------------
function bug_check() {
    
    // Remove all the old widgets.
    for (var i = 0; i < widgets.length; i++) {
        editor.removeLineWidget(widgets[i]);
    }
    widgets = [];
    
    // Get the current content line by line.
    var content_lines = editor.getValue().split(/\r?\n/);

    var bug_check_rules = <ANJI Editor.get_bug_check_rules()/>;
    
    // Loop over each line and check it for bugs.
    for (var i = 0; i < content_lines.length; i++) {
        
        var content_line = content_lines[i];
        
        // Loop over each bug check.
        for (var j = 0; j < bug_check_rules.length; j++) {
            
            var bug_check_rule = bug_check_rules[j];
            
            // If the rule is for any file type or for this file type.
            if (bug_check_rule.file_type === "" || bug_check_rule.file_type === current_file_extension) {
                try {
                    if (new RegExp(bug_check_rule.regex).test(content_line) === true) {
                        var message = bug_check_rule.message;
                        var matches = new RegExp(bug_check_rule.regex).exec(content_line);
                        if (matches.length > 1) {
                            message = message.replace("%capture%", matches[1]);
                        }
                        switch (bug_check_rule.type) {
                            case "warning":
                                add_warning(i, message, bug_check_rule.reason, bug_check_rule.fix);
                                break;
                            case "style":
                                add_style(i, message, bug_check_rule.reason, bug_check_rule.fix);
                                break;
                            default:
                            case "error":
                                add_error(i, message, bug_check_rule.reason, bug_check_rule.fix);
                                break;
                        }
                    }
                } catch (error) {
                    console.error(error);
                }
            }
        }
    }
    
    // Display a bug count.
    ui.remove_status(status_id);
    var bug_count = widgets.length;
    if (bug_count > 0) {
        status_id = ui.status("There " + presto.plural(bug_count, "is", "are") + " " + bug_count + " " + presto.plural(bug_count, "bug", "bugs"));
    }
}

function close_console() {
    presto.get("console").style.height = "0";
}

function set_console(data) {
    presto.get("console_content").innerHTML = data;
    presto.get("console").style.height = "50%";
}

function run_sql() {
    ajax.call(presto.anji("run_sql", {
        sql : editor.getValue()
    }), function(response) {
        var headers = [];
        var header_row = response[0];
        for (var i = 0; i < header_row.length; i++) {
            headers.push("<th>" + header_row[i] + "</th>");
        }
        var html = ["<tr>" + headers.join("") + "</tr>"];
        for (var y = 1; y < response.length; y++) {
            var row = [];
            for (var x = 0; x < response[y].length; x++) {
                row.push("<td>" + response[y][x] + "</td>");
            }
            html.push("<tr>" + row.join("") + "</tr>")
        }
        set_console("<table>" + html.join("") + "</table>");
    });
}

function save() {
    switch (editor_mode) {
        case "file":
            save_file();
            break;
        case "sql":
            run_sql();
            break;
    }
}

function check_for_changes() {
    return true;
}

function switch_to_file() {
    if (check_for_changes() === false) {
        return;
    }
    editor.setValue("");
    editor_mode = "file";
    presto.get("file_buttons").style.display = "block";
    presto.get("file_display").style.display = "block";
    presto.get("db_buttons").style.display = "none";
    presto.get("db_display").style.display = "none";
    editor.focus();
}

function switch_to_db() {
    if (check_for_changes() === false) {
        return;
    }
    editor.setValue("");
    editor_mode = "sql";
    editor.setOption("mode", get_mode("dummy.sql"));
    presto.get("file_buttons").style.display = "none";
    presto.get("file_display").style.display = "none";
    presto.get("db_buttons").style.display = "block";
    presto.get("db_display").style.display = "block";
    editor.focus();
}