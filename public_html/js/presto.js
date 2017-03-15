window.onerror = function(error) {
    alert(error);
};

function Presto() {
    this.get = function presto___get(id) {
        return document.getElementById(id);
    };
    this.new = function presto___new(node_type) {
        return document.createElement(node_type);
    };
    this.new_text = function presto___new_text(text) {
        return document.createTextNode(text);
    };
    this.add = function presto___add(element) {
        document.body.appendChild(element);
    };
    this.remove = function presto___remove(element) {
        document.body.removeChild(element);
    };
    this.anji = function presto___anji(anji_name, anji_args) {
        var anji_string = "/anji?cmd=" + anji_name;
        if (anji_args !== undefined) {
            for (var anji_arg in anji_args) {
                if (anji_args.hasOwnProperty(anji_arg) === true) {
                    anji_string += "&" + anji_arg + "=" + encodeURIComponent(anji_args[anji_arg]);
                }
            }
        }
        return anji_string;
    };
    this.id = function presto___id(optional_prefix) {
        var id = new Date().getTime().toString(36);
        if (optional_prefix !== undefined) {
            id = optional_prefix + "_" + id;
        }
        return id;
    }
    this.plural = function presto___plural(count, singular, pluralised) {
        if (count === 1) {
            return singular;
        } else {
            return pluralised;
        }
    }
}
presto = new Presto();