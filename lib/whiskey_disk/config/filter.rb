require 'whiskey_disk/config/filters/environment_scope_filter'
require 'whiskey_disk/config/filters/project_scope_filter'
require 'whiskey_disk/config/filters/normalize_domains_filter'
require 'whiskey_disk/config/filters/select_project_and_environment_filter'
require 'whiskey_disk/config/filters/add_environment_name_filter'
require 'whiskey_disk/config/filters/add_project_name_filter'
require 'whiskey_disk/config/filters/default_config_target_filter'

class WhiskeyDisk
  class Config
    class Filter
      attr_reader :config, :filters
  
      def initialize(config)
        @config = config
        @filters = [
          EnvironmentScopeFilter,
          ProjectScopeFilter,
          NormalizeDomainsFilter,
          SelectProjectAndEnvironmentFilter,
          AddEnvironmentNameFilter,
          AddProjectNameFilter,
          DefaultConfigTargetFilter
        ]
      end
  
      def filter_data(data)
        filters.inject(data.clone) do |result, filter|
          result = filter.new(config).filter(result)
        end
      end    
    end
  end
end
