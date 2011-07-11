require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class CheckBasicRequirementsFilter < AbstractFilter
      def has_setting?(data, key)
        data[key] and data[key].strip != ''
      end
      
      def filter(data)
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless has_setting?(data, 'environment')
        raise "Cannot determine current projec -- try rake ... to=myproject:staging, for example." unless has_setting?(data, 'project')
        data
      end
    end
  end
end

