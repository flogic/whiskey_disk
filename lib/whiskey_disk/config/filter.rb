require 'whiskey_disk/config/filters/stringify_hash_keys_filter'
require 'whiskey_disk/config/filters/environment_scope_filter'
require 'whiskey_disk/config/filters/project_scope_filter'
require 'whiskey_disk/config/filters/select_project_and_environment_filter'
require 'whiskey_disk/config/filters/add_environment_name_filter'
require 'whiskey_disk/config/filters/add_project_name_filter'
require 'whiskey_disk/config/filters/default_config_target_filter'
require 'whiskey_disk/config/filters/default_domain_filter'
require 'whiskey_disk/config/filters/hashify_domain_entries_filter'
require 'whiskey_disk/config/filters/localize_domains_filter'
require 'whiskey_disk/config/filters/check_for_duplicate_domains_filter'
require 'whiskey_disk/config/filters/convert_role_strings_to_list_filter'
require 'whiskey_disk/config/filters/drop_empty_domain_roles_filter'
require 'whiskey_disk/config/filters/normalize_ssh_options_filter'

class WhiskeyDisk
  class Config
    class Filter
      attr_reader :config, :filters
  
      def initialize(config)
        @config = config
        @filters = [
          StringifyHashKeysFilter,
          EnvironmentScopeFilter,
          ProjectScopeFilter,
          SelectProjectAndEnvironmentFilter,
          AddEnvironmentNameFilter,
          AddProjectNameFilter,
          DefaultConfigTargetFilter,
          DefaultDomainFilter,
          HashifyDomainEntriesFilter,
          LocalizeDomainsFilter,
          CheckForDuplicateDomainsFilter,
          ConvertRoleStringsToListFilter,
          DropEmptyDomainRolesFilter,
          NormalizeSshOptionsFilter
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
