require 'whiskey_disk/config/environment'
require 'whiskey_disk/config/reader'

class WhiskeyDisk
  class Config
    def fetch
      @fetch ||= reader.fetch
    end
    
    def reader
      @reader ||= Reader.new(env)
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
  end
end
