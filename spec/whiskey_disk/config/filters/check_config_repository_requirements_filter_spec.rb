require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'check_config_repository_requirements_filter'))

describe 'filtering configuration data by normalizing domains' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::CheckConfigRepositoryRequirementsFilter.new(@config)
  end

  it 'returns data if neither config_repository nor deploy_config_to is specified' do
    @filter.filter({ 'foo' => 'bar' }).should == { 'foo' => 'bar' }
  end

  describe 'when config_repository and deploy_config_to are both specified' do
    before do
      @data = { 'config_repository' => 'x', 'deploy_config_to' => 'y' }
    end

    it 'raises an exception if config_repository is unspecified' do
      @data.delete('config_repository')
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if config_repository is nil' do
      @data['config_repository'] = ''
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if config_repository is empty' do
      @data['config_repository'] = ''
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if config_repository is whitespace' do
      @data['config_repository'] = '    '
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if deploy_config_to is unspecified' do
      @data.delete('deploy_config_to')
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if deploy_config_to is nil' do
      @data['deploy_config_to'] = ''
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if deploy_config_to is empty' do
      @data['deploy_config_to'] = ''
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'raises an exception if deploy_config_to is whitespace' do
      @data['deploy_config_to'] = '    '
      lambda { @filter.filter(@data) }.should.raise
    end

    it 'should return the supplied data if config_repository has deploy_config_to and config_repository settings' do
      @filter.filter(@data).should == @data
    end
  end
end