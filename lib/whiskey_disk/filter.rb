class WhiskeyDisk
  class Config
    class EnvironmentScopeFilter
      attr_reader :config
      
      def initialize(config)
        @config = config
      end
      
      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end

      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        repository_depth(data) == 0
      end
      
      def filter(data)
        return data unless needs_environment_scoping?(data)
        { config.environment_name => data }
      end
    end
    
    class ProjectScopeFilter
      attr_reader :config
      
      def initialize(config)
        @config = config
      end
      
      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end
      
      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        repository_depth(data) == 1
      end
      
      def filter(data)
        return data unless needs_project_scoping?(data)
        config.override_project_name!(data)
        { config.project_name => data }
      end
    end
    
    class Filter
      attr_reader :config
  
      def initialize(config)
        @config = config
      end
  
      def filter_data(data)
        current = EnvironmentScopeFilter.new(config).filter(data.clone)
        current = ProjectScopeFilter.new(config).filter(current)
        current = config.normalize_domains(current)
        current = config.select_project_and_environment(current)
        current = config.add_environment_name(current)
        current = config.add_project_name(current)
        current = config.default_config_target(current)
      end    
    end
  end
end
