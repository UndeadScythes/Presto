external_require "mysql2"

class Sql < Anji
    
    def run_sql(options)
        sql = options["sql"]
        
        client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => ConfigManager.get("presto_db_root_password"))

        begin
            results = client.query(sql)
        rescue => error
            return JSON.generate([["SQL ERROR"], [error]])
        end
        
        headers = []
        results.each do |row|
            row.each do |key, value|
                headers << key
            end
            break
        end
        
        response = []
        results.each do |row|
            row_data = []
            headers.each do |key, _|
                row_data << row[key]
            end
            response << row_data
        end
        
        return JSON.generate([headers] + response)
    end
    
    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return ["run_sql"]
    end
end