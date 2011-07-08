require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class NormalizeSshOptionsFilter < AbstractFilter
      def drop_empties(options_list)
        options_list.select {|option| option and option != '' }
      end
      
      def drop_empty_ssh_options_for_domain(domain)
        result = drop_empties([ domain['ssh_options'] ].flatten)
        if result and result != []
          domain.merge('ssh_options' => result)
        else
          domain.reject {|k,v| k == 'ssh_options' }
        end
      end
      
      def normalize_ssh_options(domains_list)
        domains_list.collect { |domain| drop_empty_ssh_options_for_domain(domain) }
      end
      
      def filter(data)
        data.merge('domain' => normalize_ssh_options(data['domain']))
      end
    end
  end
end

