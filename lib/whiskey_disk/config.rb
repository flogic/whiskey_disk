require 'yaml'
require 'uri'
require 'open-uri'
require 'whiskey_disk/config/filter'
require 'whiskey_disk/config/environment'
require 'whiskey_disk/config/locator'

class WhiskeyDisk
  class Config
    def fetch
      @fetch ||= filter_data(load_data)
    end
    
    def filter
      @filter ||= WhiskeyDisk::Config::Filter.new(self)
    end
    
    # called only by #fetch
    def filter_data(data)
      filter.filter_data(data)
    end
    
    def env
      @env ||= Environment.new
    end
    
    def debug?
      env.debug?
    end
    
    def domain_limit
      env.domain_limit
    end
    
    def check_staleness?
      env.check_staleness?
    end

    def environment_name
      fetch['environment']
    end

    def project_name
      fetch['project']
    end
    
    def configuration_file
      @location ||= locator.location
    end
    
    def locator
      @locator ||= Locator.new(env)
    end
    
    def load_data
      YAML.load(configuration_data)
    rescue Exception => e
      raise %Q{Error reading configuration file [#{configuration_file}]: "#{e}"}
    end

    def configuration_data
      open(configuration_file) {|f| f.read }
    end
  end
end
