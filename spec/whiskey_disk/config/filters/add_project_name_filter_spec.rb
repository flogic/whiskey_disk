require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'add_project_name_filter'))

describe 'filtering configuration data by adding the project name' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::AddProjectNameFilter.new(@config)
    ENV['to'] = 'project:environment'
  end
  
  it 'adds an environment value when none is present' do
    @filter.filter('foo' => 'bar').should == { 'project' => 'project', 'foo' => 'bar' }
  end
  
  it 'overwrites an environment value when one is present' do
    @filter.filter('project' => 'baz', 'foo' => 'bar').should == { 'project' => 'project', 'foo' => 'bar' }      
  end  
end