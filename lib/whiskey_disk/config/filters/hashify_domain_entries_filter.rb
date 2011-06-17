require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class HashifyDomainEntriesFilter < AbstractFilter
      def needs_hashing?(domain)
        ! domain.respond_to?(:keys)
      end
      
      def hashify_domain(domain)
        needs_hashing?(domain) ? { 'name' => domain } : domain
      end
      
      def hashify_domains(domain_list)
        domain_list.collect {|domain| hashify_domain(domain) }
      end

      def filter(data)
        data.merge('domain' => hashify_domains(data['domain']))
      end
    end
  end
end

