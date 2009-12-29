require File.expand_path(File.join(File.dirname(__FILE__), 'tasks', 'deploy'))
require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'config'))

class WhiskeyDisk
  class << self
    def configuration
      @configuration ||= WhiskeyDisk::Config.fetch
    end
    
    def [](key)
      configuration[key.to_s]
    end
    
    def reset
      @configuration = nil
    end
    
    def remote?
      ! (self[:domain].nil? or self[:domain] == '')
    end
  end
end