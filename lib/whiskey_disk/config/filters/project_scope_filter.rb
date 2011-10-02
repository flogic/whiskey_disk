require 'whiskey_disk/config/abstract_filter'
require 'whiskey_disk/config/filters/modules/scope_helper'

class WhiskeyDisk
  class Config
    class ProjectScopeFilter < AbstractFilter
      include ScopeHelper

      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end

      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        repository_depth(data) == 1
      end

      # TODO: why do we continue to need override_project_name! ?
      # TODO: this is invasive into Config's implementation
      def override_project_name!(data)
        return if ENV['to'] && ENV['to'] =~ /:/
        ENV['to'] = data[environment_name]['project'] + ':' + ENV['to'] if data[environment_name]['project']
      end

      def filter(data)
        return data unless needs_project_scoping?(data)
        override_project_name!(data)
        { project_name => data }
      end
    end
  end
end