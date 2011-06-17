require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class DefaultDomainFilter < AbstractFilter
      def filter(data)
        data.has_key?('domain') ? data : data.merge('domain' => { 'name' => 'local' })
      end
    end
  end
end

