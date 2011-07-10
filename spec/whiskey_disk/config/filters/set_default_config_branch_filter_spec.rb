require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'set_default_config_branch_filter'))

describe 'setting the default branch for a config repo' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::SetDefaultConfigBranchFilter.new(@config)
  end

  it 'does not set the config branch if the config_repository is not set' do
    @filter.filter({ })['config_branch'].should == nil
  end

  describe 'when the config_repository is non-empty' do
    it 'sets a non-specified branch to "master"' do
      @filter.filter({ 'config_repository' => 'foo'})['config_branch'].should == 'master'
    end
  
    it 'sets an empty branch to "master"' do
      @filter.filter({ 'config_repository' => 'foo', 'config_branch' => '' })['config_branch'].should == 'master'
    end
  
    it 'sets a whitespace branch to master' do
      @filter.filter({ 'config_repository' => 'foo', 'config_branch' => '  ' })['config_branch'].should == 'master'
    end
  
    it 'sets a nil branch to master' do
      @filter.filter({ 'config_repository' => 'foo', 'config_branch' => nil })['config_branch'].should == 'master'
    end
  
    it 'leaves a "master" branch as "master"' do
      @filter.filter({ 'config_repository' => 'foo', 'config_branch' => 'master' })['config_branch'].should == 'master'
    end

    it 'leaves a non-empty, non-"master" set' do
      @filter.filter({ 'config_repository' => 'foo', 'config_branch' => 'bacon' })['config_branch'].should == 'bacon'
    end
  end
end
