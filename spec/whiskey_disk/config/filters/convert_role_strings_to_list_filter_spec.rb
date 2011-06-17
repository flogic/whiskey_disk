require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'convert_role_strings_to_list_filter'))

describe 'converting domain role strings into lists' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::ConvertRoleStringsToListFilter.new(@config)
  end
  
  it 'handles single strings' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'roles' => 'baz' },
        { 'name' => 'bar', 'roles' => 'xyzzy' },
      ]
    }
    
    @filter.filter(@data).should == {      
      'domain' => [
        { 'name' => 'foo', 'roles' => [ 'baz' ] },
        { 'name' => 'bar', 'roles' => [ 'xyzzy' ] },
      ]
    }
  end
  
  it 'does not touch domains without roles' do
    @data = {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar' }
      ]
    }
    
    @filter.filter(@data).should == @data  
  end
  
  it 'leaves existing role lists alone' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'roles' => [ 'baz' ] },
        { 'name' => 'bar', 'roles' => [ 'xyzzy', 'quux' ] },
      ]
    }
    
    @filter.filter(@data).should == @data
  end
end