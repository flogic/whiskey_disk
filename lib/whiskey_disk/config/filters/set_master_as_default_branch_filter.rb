require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class SetMasterAsDefaultBranchFilter < AbstractFilter
      def default_branch(data)
        return data['branch'] if data['branch'] and data['branch'].strip != ''
        'master'
      end

      def filter(data)
        data.merge('branch' => default_branch(data))
      end
    end
  end
end