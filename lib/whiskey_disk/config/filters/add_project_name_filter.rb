require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class AddProjectNameFilter < AbstractFilter
      def filter(data)
        data.merge( { 'project' => project_name } )
      end
    end
  end
end
