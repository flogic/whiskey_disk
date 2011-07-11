require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class AddProjectNameFilter < AbstractFilter
      def defaulted_project_name
        project_name || 'unnamed_project'
      end
      
      def filter(data)
        data.merge( { 'project' => defaulted_project_name } )
      end
    end
  end
end
