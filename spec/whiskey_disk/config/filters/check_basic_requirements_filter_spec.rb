require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'check_basic_requirements_filter'))

describe 'verifying that environment name and project name are set' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::CheckBasicRequirementsFilter.new(@config)
    @data = { 'environment' => 'foo', 'project' => 'bar' }
  end

  it 'should return the supplied data if both project name and environment name are set' do
    @filter.filter(@data).should == @data
  end

  it 'raises an exception if project name is unset' do
    @data.delete('project')
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if project name is nil' do
    @data['project'] = nil
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if project name is empty' do
    @data['project'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if project name is whitespace' do
    @data['project'] = '   '
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if environment name is unset' do
    @data.delete('environment')
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if environment name is nil' do
    @data['environment'] = nil
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if environment name is empty' do
    @data['environment'] = ''
    lambda { @filter.filter(@data) }.should.raise
  end

  it 'raises an exception if environment name is whitespace' do
    @data['environment'] = '   '
    lambda { @filter.filter(@data) }.should.raise
  end
end