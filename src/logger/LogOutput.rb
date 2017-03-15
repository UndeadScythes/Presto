class LogOutput
    
    @@log_file_path = nil
    
    @log_file = nil
    
    def initialize(log_name)
        @log_name = log_name
    end

    def write(*arguments)
        if @log_file == nil && @@log_file_path != nil
            @log_file = File.open(File.join(@@log_file_path, "#{@log_name}.log"), "w")
        end
        STDOUT.write(*arguments)
        if @log_file != nil
            @log_file.write(*arguments)
        end
    end

    def close()
        if @log_file != nil
            @log_file.close()
            @log_file = nil
        end
    end

    def self.set_log_file_path(log_file_path)
        @@log_file_path = log_file_path
    end
    
end