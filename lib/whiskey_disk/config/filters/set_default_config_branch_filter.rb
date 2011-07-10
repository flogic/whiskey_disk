require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class SetDefaultConfigBranchFilter < AbstractFilter
      def default_config_branch(data)
        return data['config_branch'] if data['config_branch'] and data['config_branch'].strip != ''
        'master'        
      end
      
      def has_config_repository?(data)
        data['config_repository'] and data['config_repository'] != ''
      end
      
      def filter(data)
        return data.merge('config_branch' => default_config_branch(data)) if has_config_repository?(data)
        data
      end
    end
  end
end