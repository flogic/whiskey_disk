require 'whiskey_disk/config/environment'
require 'whiskey_disk/config/reader'

class WhiskeyDisk
  class Config
    def env
      reader.env
    end

    def fetch
      @fetch ||= reader.fetch
    end

    def reader
      @reader ||= Reader.new(nil)
    end

    def environment_name
      fetch['environment']
    end

    def project_name
      fetch['project']
    end

    def debug?
      reader.debug?
    end

    def domain_limit
      reader.domain_limit
    end

    def check_staleness?
      reader.check_staleness?
    end
  end
end
