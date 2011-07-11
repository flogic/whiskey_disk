Dir[File.join(File.dirname(__FILE__), 'filters/*_filter.rb')].each {|file| require file }

class WhiskeyDisk
  class Config
    class Filter
      attr_reader :config, :filters
  
      def initialize(config)
        @config = config
        @filters = [
          StringifyHashKeysFilter,
          EnvironmentScopeFilter, ProjectScopeFilter, SelectProjectAndEnvironmentFilter,
          CheckRepositoryRequirementsFilter, CheckConfigRepositoryRequirementsFilter,
          AddEnvironmentNameFilter, AddProjectNameFilter,
          DefaultConfigTargetFilter, DefaultDomainFilter,
          HashifyDomainEntriesFilter, LocalizeDomainsFilter, CheckForDuplicateDomainsFilter,
          ConvertRoleStringsToListFilter, DropEmptyDomainRolesFilter,
          NormalizeSshOptionsFilter,
          SetDefaultBranchFilter, SetDefaultConfigBranchFilter,
          CheckBasicRequirementsFilter
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
