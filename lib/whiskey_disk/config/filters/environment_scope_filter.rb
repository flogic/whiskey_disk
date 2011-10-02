require 'whiskey_disk/config/abstract_filter'
require 'whiskey_disk/config/filters/modules/scope_helper'

class WhiskeyDisk
  class Config
    class EnvironmentScopeFilter < AbstractFilter
      include ScopeHelper

      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        repository_depth(data) == 0
      end

      def filter(data)
        return data unless needs_environment_scoping?(data)
        { environment_name => data }
      end
    end
  end
end