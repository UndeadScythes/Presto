# =============================================================================
# Variable - Description.
# =============================================================================
class Variable < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Variable")


    # -------------------------------------------------------------------------
    # Perform a task.
    # -------------------------------------------------------------------------
    def replace(options)

        variable_name = options["name"]
        text_match = options["match"]
        replace = options["replace"]

        variable = ConfigManager.get(variable_name)

        if variable.kind_of?(Array)
            variable.each do |value|
                value.sub!(text_match, replace)
            end
        elsif variable.kind_of(String)
            varaible.sub!(text_match, replace)
        end

        return ""
    end

    def self.do_capitalise(value)
        non_capitalisable_words = [
            "if", "the", "an", "a", "it", "of"
        ]
        @@LOGGER.debug("Capitalising #{value}")
        value = value.downcase()
        variable_parts = value.split(" ")
        new_variable_parts = []
        variable_parts.each do |word|
            if !non_capitalisable_words.include?(word)
                new_variable_parts << word[0, 1].upcase + word[1, word.length - 1]
            end
        end
        result = new_variable_parts.join(" ")
        @@LOGGER.debug("Resulting value #{result}")
        return result
    end

    # -------------------------------------------------------------------------
    # Perform a task.
    # -------------------------------------------------------------------------
    def capitalise(options)
        variable_name = options["name"]
        variable = ConfigManager.get(variable_name)
        new_variable = variable
        if variable.kind_of?(Array)
            new_variable = []
            variable.each do |value|
                new_variable << Variable.do_capitalise(value)
            end
        elsif variable.kind_of?(String)
            new_variable = Variable.do_capitalise(variable)
        else
            @@LOGGER.warn("Non string variable passed to capitalise")
        end
        ConfigManager.delete(variable_name)
        ConfigManager.set(variable_name, new_variable)

        return ""
    end

    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return []
    end

end