require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk'))
require 'rake'

describe 'requiring the main library' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'tasks', 'deploy.rb'))
  end

  after do
    Rake.application = nil
  end

  it 'should make the deploy:setup rake task available' do
    Rake::Task.task_defined?('deploy:setup').should.be.true
  end

  it 'should make the deploy:now rake task available' do
    Rake::Task.task_defined?('deploy:now').should.be.true
  end
end

describe 'WhiskeyDisk' do
  describe 'ensuring that the parent path for the main repository checkout is present' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return({})
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.ensure_main_parent_path_is_present }.should.raise
    end
    
    it 'should attempt to create the parent path for the repository' do
      WhiskeyDisk.ensure_main_parent_path_is_present
      WhiskeyDisk.buffer.last.should.match(%r{mkdir -p /path/to/main})
      WhiskeyDisk.buffer.last.should.not.match(%r{/path/to/main/repo})
    end
  end

  describe 'ensuring that the parent path for the configuration repository checkout is present' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return({})
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.ensure_config_parent_path_is_present }.should.raise
    end
    
    it 'should attempt to create the parent path for the repository' do
      WhiskeyDisk.ensure_config_parent_path_is_present
      WhiskeyDisk.buffer.last.should.match(%r{mkdir -p /path/to/config})
      WhiskeyDisk.buffer.last.should.not.match(%r{/path/to/config/repo})
    end
  end
  
  describe 'checking out the main repository' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'repository' => 'git@ogtastic.com:whiskey_disk.git' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('deploy_to' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.checkout_main_repository }.should.raise
    end
    
    it 'should fail if the repository is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('repository' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.checkout_main_repository }.should.raise
    end
    
    it 'should work from the main repository checkout parent path' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/main})
      WhiskeyDisk.buffer.join(' ').should.not.match(%r{cd /path/to/main/repo})
    end
    
    it 'should attempt to clone the main repository to the repository checkout path' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{clone #{@parameters['repository']} repo})
    end
    
    it 'should ignore errors from failing to clone an existing repository' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{\|\| true})
    end
  end
  
  describe 'installing a post-receive hook on the checked out main repository' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('deploy_to' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.install_hooks }.should.raise
    end
    
    # FIXME -- TODO:  MORE HERE
  end
  
  describe 'checking out the configuration repository' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo', 'config_repository' => 'git@ogtastic.com:config.git' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end

    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('deploy_config_to' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.checkout_configuration_repository }.should.raise
    end

    it 'should fail if the configuration repository is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('config_repository' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.checkout_configuration_repository }.should.raise
    end

    it 'should work from the configuration repository checkout parent path' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/config})
      WhiskeyDisk.buffer.join(' ').should.not.match(%r{cd /path/to/config/repo})
    end

    it 'should attempt to clone the configuration repository to the repository checkout path' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{clone #{@parameters['config_repository']} repo})
    end

    it 'should ignore errors from failing to clone an existing repository' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{\|\| true})
    end    
  end
  
  describe 'updating the main repository checkout' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('deploy_to' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.update_main_repository_checkout }.should.raise
    end
    
    it 'should work from the main repository checkout path' do
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    it 'should attempt to fetch only the master branch from the origin if no branch is specified' do
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/master:refs/remotes/origin/master})
    end
    
    it 'should attempt to fetch the specified branch from the origin if a branch is specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge({'branch' => 'production'}))
      WhiskeyDisk.reset
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/production:refs/remotes/origin/production})
    end

    it 'should attempt to reset the master branch from the origin if no branch is specified' do
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end
    
    it 'should attempt to reset the specified branch from the origin if a branch is specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge({'branch' => 'production'}))
      WhiskeyDisk.reset
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/production})
    end
  end
  
  describe 'updating the configuration repository checkout' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo' }
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters)
      WhiskeyDisk.reset
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk::Config.stub!(:fetch).and_return(@parameters.merge('deploy_config_to' => nil))
      WhiskeyDisk.reset
      lambda { WhiskeyDisk.update_configuration_repository_checkout }.should.raise
    end
    
    it 'should work from the main repository checkout path' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/config/repo})
    end
    
    it 'should attempt to fetch only the master branch from the origin' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/master:refs/remotes/origin/master})
    end
    
    it 'should attempt to reset the master branch from the origin' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end
  end
  
  describe 'refreshing the configuration' do
    
  end
  
  describe 'running post setup hooks' do
    
  end
  
  describe 'running post deployment hooks' do
    
  end
  
  describe 'flushing changes' do

  end
end

