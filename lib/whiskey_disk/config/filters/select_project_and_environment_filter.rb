require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class SelectProjectAndEnvironmentFilter < AbstractFilter
      def filter(data)
        raise "No configuration file defined data for project `#{project_name}`, environment `#{environment_name}`" unless data and data[project_name] and data[project_name][environment_name]
        data[project_name][environment_name]
      end
    end
  end
end