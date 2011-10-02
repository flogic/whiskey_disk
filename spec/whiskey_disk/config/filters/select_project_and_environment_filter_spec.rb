require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'select_project_and_environment_filter'))

describe 'filtering configuration data by selecting the data for the project and environment' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::SelectProjectAndEnvironmentFilter.new(@config)

    @data = {
      'project' => { 'environment' => { 'a' => 'b' } },
      'other'   => { 'missing' => { 'c' => 'd' } },
    }
  end

  it 'fails when the specified project cannot be found' do
    ENV['to'] = @env = 'something:environment'
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'fails when the specified environment cannot be found for the specified project' do
    ENV['to'] = @env = 'other:environment'
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'returns only the data for the specified project and environment' do
    ENV['to'] = @env = 'project:environment'
    @filter.filter(@data).should == @data['project']['environment']
  end
end