require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class DefaultConfigTargetFilter < AbstractFilter
      def filter(data)
        return data if data['config_target']
        data.merge( { 'config_target' => environment_name })
      end
    end
  end
end