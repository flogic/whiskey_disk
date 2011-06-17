require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class AddEnvironmentNameFilter < AbstractFilter
      def filter(data)
        data.merge( { 'environment' => environment_name } )
      end
    end
  end
end
