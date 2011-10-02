require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'set_default_branch_filter'))

describe 'setting the default branch for a main repo' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::SetDefaultBranchFilter.new(@config)
  end

  it 'sets a non-specified branch to "master"' do
    @filter.filter({ }).should == { 'branch' => 'master' }
  end

  it 'sets an empty branch to "master"' do
    @filter.filter({ 'branch' => '' }).should == { 'branch' => 'master' }
  end

  it 'sets a whitespace branch to master' do
    @filter.filter({ 'branch' => '    ' }).should == { 'branch' => 'master' }
  end

  it 'sets a nil branch to master' do
    @filter.filter({ 'branch' => nil }).should == { 'branch' => 'master' }
  end

  it 'leaves a "master" branch as "master"' do
    @filter.filter({ 'branch' => 'master' }).should == { 'branch' => 'master' }
  end

  it 'leaves a non-empty, non-"master" set' do
    @filter.filter({ 'branch' => 'bacon' }).should == { 'branch' => 'bacon' }
  end
end

