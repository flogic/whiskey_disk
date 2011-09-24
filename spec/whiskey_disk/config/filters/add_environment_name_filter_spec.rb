require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'add_environment_name_filter'))

describe 'filtering configuration data by adding the environment name' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::AddEnvironmentNameFilter.new(@config)
    
    ENV['to'] = 'project:environment'
  end
  
  it 'adds an environment value when none is present' do
    @filter.filter('foo' => 'bar').should == { 'environment' => 'environment', 'foo' => 'bar' }
  end
  
  it 'overwrites an environment value when one is present' do
    @filter.filter('environment' => 'baz', 'foo' => 'bar').should == { 'environment' => 'environment', 'foo' => 'bar' }      
  end
end
