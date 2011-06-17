require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class ConvertRoleStringsToListFilter < AbstractFilter
      def convert_roles_for_domain(domain)
        return domain unless domain['roles']
        domain.merge('roles' => [ domain['roles'] ].flatten)
      end
      
      def convert_all_roles(domains_list)
        domains_list.collect {|domain| convert_roles_for_domain(domain) }
      end
      
      def filter(data)
        data.merge('domain' => convert_all_roles(data['domain']))
      end
    end
  end
end
