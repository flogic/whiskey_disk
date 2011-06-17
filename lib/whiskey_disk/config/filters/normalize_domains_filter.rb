require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class NormalizeDomainsFilter < AbstractFilter
      def compact_list(list)
        [ list ].flatten.delete_if { |d| d.nil? or d == '' }
      end

      def normalize_domain(data)
        data.collect do |d|
          row = { 'name' => d['name'] }
          roles = compact_list(d['roles'])
          row['roles'] = roles unless roles.empty?
          row
        end
      end

      def filter(data)
        data.merge('domain' => normalize_domain(data['domain']))
      end
    end
  end
end

