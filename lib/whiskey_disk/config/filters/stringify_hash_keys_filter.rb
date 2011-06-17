require 'whiskey_disk/config/abstract_filter'

class WhiskeyDisk
  class Config
    class StringifyHashKeysFilter < AbstractFilter
      def stringify_hash(data)
        result = {}
        data.each_pair do |key, value|
          result[key.to_s] = stringify(value)
        end
        result
      end

      def stringify(structure)
        return structure.clone unless structure.respond_to? :keys
        stringify_hash(structure)
      end
      
      def filter(data)
        stringify(data)
      end
    end
  end
end

