class Os
   
    @@LOGGER = LogManager.get_logger("Os")
    
    def self.run(command)
        @@LOGGER.info("Running #{command}")
        response = `#{command} 2>&1`
        @@LOGGER.debug("Response was #{response}")
        return response
    end
end