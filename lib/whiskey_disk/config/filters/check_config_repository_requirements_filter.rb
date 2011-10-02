require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class CheckConfigRepositoryRequirementsFilter < AbstractFilter
      def has_setting?(data, key)
        data[key] and data[key].strip != ''
      end

      def filter(data)
        return data unless data.has_key?('config_repository') or data.has_key?('deploy_config_to')
        raise "missing 'config_repository' setting in configuration file for project [#{environment_name}], target [#{environment_name}]" unless has_setting?(data, 'config_repository')
        raise "missing 'deploy_config_to' setting in configuration file for project [#{environment_name}], target [#{environment_name}]" unless has_setting?(data, 'deploy_config_to')
        data
      end
    end
  end
end

