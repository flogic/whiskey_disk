class WhiskeyDisk
  class Config
    class AbstractFilter
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def env
        config.env
      end

      def project_name
        env.project_name
      end

      def environment_name
        env.environment_name
      end
    end
  end
end