class WhiskeyDisk
  class Config
    class Environment
      def debug?
        flag_is_true?('debug')
      end

      def check_staleness?
        flag_is_true?('check')
      end

      def domain_limit
        key_or_false?('only')
      end

      def path
        key_or_false?('path')
      end

      def project_name
        specified_project_name || 'unnamed_project'
      end

      def specified_project_name
        return false unless has_key?('to')
        return false unless ENV['to'] =~ /:/
        ENV['to'].split(/:/).first
      end

      def environment_name
        return false unless has_key?('to')
        return ENV['to'] unless ENV['to'] =~ /:/
        ENV['to'].split(/:/)[1]
      end

      def flag_is_true?(key)
        !!(has_key?(key) && ENV[key] =~ /^(?:t(?:rue)?|y(?:es)?|1)$/)
      end

      def key_or_false?(key)
        has_key?(key) ? ENV[key] : false
      end

      def has_key?(key)
        ENV[key] && ENV[key] != ''
      end
    end
  end
end