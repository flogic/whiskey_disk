require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'stringify_hash_keys_filter'))

describe 'filtering configuration data to only have symbol hash keys' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::StringifyHashKeysFilter.new(@config)
    @data = {
      'a' => {
        :x => 'y',
        'c' => 'd',
        :e => {
          'f' => ['a', 'b', 'c']
        }
      },
      :b => [ '1', '2', '3' ]
    }
  end

  it 'recursively stringifies hash keys in the provided data structure' do
    @filter.filter(@data).should == {
      'a' => {
        'x' => 'y',
        'c' => 'd',
        'e' => {
          'f' => [ 'a', 'b', 'c' ]
        }
      },
      'b' => [ '1', '2', '3' ]
    }
  end

  it 'clones value data so that the original data structure is not shared' do
    original = @data.clone
    result = @filter.filter(@data)
    result['a']['e']['f'] << 'd'
    @data.should == original
  end
end