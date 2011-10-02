require 'whiskey_disk/config/filter'
require 'whiskey_disk/config/locator'
require 'open-uri'
require 'yaml'

class WhiskeyDisk
  class Config
    class Reader
      def initialize(dummy)
      end

      def fetch
        filter_data(load_data)
      end

      def filter_data(data)
        filter.filter_data(data)
      end

      def filter
        @filter ||= WhiskeyDisk::Config::Filter.new(self)
      end

      def load_data
        YAML.load(configuration_data)
      rescue Exception => e
        raise %Q{Error reading configuration file [#{configuration_file}]: "#{e.to_s}"}
      end

      def configuration_data
        open(configuration_file) {|f| f.read }
      end

      def configuration_file
        @location ||= locator.location
      end

      def locator
        @locator ||= Locator.new(env)
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
    end
  end
end
