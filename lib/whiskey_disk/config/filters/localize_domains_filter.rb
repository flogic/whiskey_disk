require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class LocalizeDomainsFilter < AbstractFilter
      def is_local?(name)
        name.nil? or name == ''
      end
      
      def localize(name)
        is_local?(name) ? 'local' : name
      end
      
      def localize_domains(domain_list)
        domain_list.collect {|domain| domain.merge('name' => localize(domain['name'])) }
      end

      def filter(data)
        data.merge('domain' => localize_domains(data['domain']))
      end
    end
  end
end

