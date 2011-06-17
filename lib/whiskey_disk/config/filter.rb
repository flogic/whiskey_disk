require 'whiskey_disk/config/filters/environment_scope_filter'
require 'whiskey_disk/config/filters/project_scope_filter'
require 'whiskey_disk/config/filters/normalize_domains_filter'
require 'whiskey_disk/config/filters/select_project_and_environment_filter'
require 'whiskey_disk/config/filters/add_environment_name_filter'
require 'whiskey_disk/config/filters/add_project_name_filter'
require 'whiskey_disk/config/filters/default_config_target_filter'
require 'whiskey_disk/config/filters/stringify_hash_keys_filter'
require 'whiskey_disk/config/filters/check_for_duplicate_domains_filter'

class WhiskeyDisk
  class Config
    class Filter
      attr_reader :config, :filters
  
      def initialize(config)
        @config = config
        @filters = [
          EnvironmentScopeFilter,
          ProjectScopeFilter,
          SelectProjectAndEnvironmentFilter,
          AddEnvironmentNameFilter,
          AddProjectNameFilter,
          DefaultConfigTargetFilter,
          NormalizeDomainsFilter,
          StringifyHashKeysFilter,
          CheckForDuplicateDomainsFilter
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
