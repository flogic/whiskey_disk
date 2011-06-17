require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'environment_scope_filter'))

describe 'filtering configuration data by adding environment scoping' do
  before do
    ENV['to'] = @env = 'foo:staging'

    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::EnvironmentScopeFilter.new(@config)

    @bare_data  = { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] }
    @env_data   = { 'staging' => @bare_data }
    @proj_data  = { 'foo' => @env_data }
  end

  it 'fails if the configuration data is not a hash' do
    lambda { @filter.filter([]) }.should.raise
  end

  it 'returns the original data if it has both project and environment scoping' do
    @filter.filter(@proj_data).should == @proj_data
  end

  it 'returns the original data if it has environment scoping' do
    @filter.filter(@env_data).should == @env_data
  end

  it 'returns the data wrapped in an environment scope if it has no environment scoping' do
    @filter.filter(@bare_data).should == { 'staging' => @bare_data }
  end
end