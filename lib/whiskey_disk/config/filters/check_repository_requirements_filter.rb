require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class CheckRepositoryRequirementsFilter < AbstractFilter
      def has_setting?(data, key)
        data[key] and data[key].strip != ''
      end
      
      def filter(data)
        raise "missing 'repository' setting in configuration file for project [#{environment_name}], target [#{environment_name}]" unless has_setting?(data, 'repository')
        raise "missing 'deploy_to' setting in configuration file for project [#{environment_name}], target [#{environment_name}]" unless has_setting?(data, 'deploy_to')
        data
      end
    end
  end
end

