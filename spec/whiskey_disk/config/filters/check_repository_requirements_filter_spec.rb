require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'check_repository_requirements_filter'))

describe 'filtering configuration data by normalizing domains' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::CheckRepositoryRequirementsFilter.new(@config)
    @data = { 'repository' => 'x', 'deploy_to' => 'y' }
  end

  it 'raises an exception if repository is unspecified' do
    @data.delete('repository')
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if repository is nil' do
    @data['repository'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if repository is empty' do
    @data['repository'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if repository is whitespace' do
    @data['repository'] = '    '
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if deploy_to is unspecified' do
    @data.delete('deploy_to')
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if deploy_to is nil' do
    @data['deploy_to'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if deploy_to is empty' do
    @data['deploy_to'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if deploy_to is whitespace' do
    @data['deploy_to'] = '    '
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'should return the supplied data if repository has deploy_to and repository settings' do
    @filter.filter(@data).should == @data
  end
end