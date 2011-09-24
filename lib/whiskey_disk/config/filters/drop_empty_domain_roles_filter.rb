require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class DropEmptyDomainRolesFilter < AbstractFilter
      def has_empty_role?(domain)
        return true unless domain.has_key?('roles')
        return true if domain['roles'].nil?

        roles = domain['roles'].uniq.compact
        return true if roles == [ '' ]
        return true if roles == []
        
        false
      end
      
      def drop_empty_roles_for_domain(domain)
        return domain unless has_empty_role?(domain)
        domain.reject {|key, value| key == 'roles' }
      end
      
      def drop_empty_domain_roles(domains_list)
        domains_list.collect { |domain| drop_empty_roles_for_domain(domain) }
      end
      
      def filter(data)
        data.merge('domain' => drop_empty_domain_roles(data['domain']))
      end
    end
  end
end

