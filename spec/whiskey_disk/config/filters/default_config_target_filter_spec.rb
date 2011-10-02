require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'default_config_target_filter'))

describe 'filtering configuration data by defaulting the config target' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::DefaultConfigTargetFilter.new(@config)
    ENV['to'] = 'project:environment'
  end

  it 'adds a config_target value set to the environment name when none is present' do
    @filter.filter('foo' => 'bar').should == { 'config_target' => 'environment', 'foo' => 'bar' }
  end

  it 'preserves the existing config_target when one is present' do
    @filter.filter('config_target' => 'baz', 'foo' => 'bar').should == { 'config_target' => 'baz', 'foo' => 'bar' }
  end
end
