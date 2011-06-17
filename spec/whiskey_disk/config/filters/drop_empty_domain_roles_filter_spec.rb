require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'drop_empty_domain_roles_filter'))

describe 'converting domain role strings into lists' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::DropEmptyDomainRolesFilter.new(@config)
  end
  
  it 'drops roles with nil values' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'roles' => nil },
        { 'name' => 'bar', 'roles' => nil }
      ]
    }
    
    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar' }
      ]
    }
  end
  
  it 'drops roles with empty list values' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'roles' => [] },
        { 'name' => 'bar', 'roles' => [] }
      ]
    }
    
    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar' }
      ]
    }    
  end
  
  it 'preserves non-empty roles' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'roles' => nil },
        { 'name' => 'bar', 'roles' => [] },
        { 'name' => 'baz', 'roles' => [ 'x', 'y', 'z' ] }
      ]
    }
    
    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz', 'roles' => [ 'x', 'y', 'z' ] }
      ]
    }
  end
end