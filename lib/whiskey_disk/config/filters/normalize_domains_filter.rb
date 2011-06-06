require 'whiskey_disk/config/abstract_filter'

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

      def check_duplicates(project, target, domain_list)
        seen = {}
        domain_list.each do |domain|
          raise "duplicate domain [#{domain[:name]}] in configuration file for project [#{project}], target [#{target}]" if seen[domain[:name]]
          seen[domain[:name]] = true
        end
      end

      def filter(data)
        data.each_pair do |project, project_data|
          project_data.each_pair do |target, target_data|
            target_data['domain'] = check_duplicates(project, target, normalize_domain(target_data['domain']))
          end
        end
        data
      end
    end
  end
end

