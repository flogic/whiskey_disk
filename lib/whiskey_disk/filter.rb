class WhiskeyDisk
  class Config
    class Filter
      attr_reader :config
  
      def initialize(config)
        @config = config
      end
  
      def filter_data(data)
        current = config.add_environment_scoping(data.clone)
        current = config.add_project_scoping(current)
        current = config.normalize_domains(current)
        current = config.select_project_and_environment(current)
        current = config.add_environment_name(current)
        current = config.add_project_name(current)
        current = config.default_config_target(current)
      end    
    end
  end
end
