class WhiskeyDisk
  class Config
    class AbstractFilter
      attr_reader :config
  
      def initialize(config)
        @config = config
      end
  
      def project_name
        config.project_name
      end
  
      def environment_name
        config.environment_name
      end
    end
  end
end