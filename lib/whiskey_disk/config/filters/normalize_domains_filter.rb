require 'whiskey_disk/config/abstract_filter'

#TODO: filter to symbolize hash keys

class WhiskeyDisk
  class Config
    class NormalizeDomainsFilter < AbstractFilter
      def localize_domain_list(list)
        [ list ].flatten.collect { |d| (d.nil? or d == '') ? 'local' : d }
      end

      def compact_list(list)
        [ list ].flatten.delete_if { |d| d.nil? or d == '' }
      end

      def normalize_domain(data)
        compacted = localize_domain_list(data)
        compacted = [ 'local' ] if compacted.empty?

        compacted.collect do |d|
          if d.respond_to?(:keys)
            row = { :name => (d['name'] || d[:name]) }
            roles = compact_list(d['roles'] || d[:roles])
            row[:roles] = roles unless roles.empty?
            row
          else
            { :name => d }
          end
        end
      end

      def filter(data)
        data.merge('domain' => normalize_domain(data['domain']))
      end
    end
  end
end

