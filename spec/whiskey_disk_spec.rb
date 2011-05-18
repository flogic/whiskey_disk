require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk'))
require 'rake'

# @whiskey_disk subclass that allows us to test in what order ssh commands are 
#   issued by @whiskey_disk.run
class TestOrderedExecution < WhiskeyDisk
  class << self
    def commands
      result = @commands
      @commands = []
      result
    end
    
    def system(*args)
      @commands ||= []
      @commands << args.join(' ')
    end
  end
end

describe 'requiring the main library' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk', 'rake.rb'))
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

describe '@whiskey_disk' do
  before do
    @whiskey_disk = WhiskeyDisk.new
  end
  
  describe 'determining if the deployment is remote' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      @whiskey_disk.configuration = @parameters
    end
    
    it 'should allow a domain argument' do
      lambda { @whiskey_disk.remote?('domain') }.should.not.raise(ArgumentError)
    end
    
    it 'should require a domain argument' do
      lambda { @whiskey_disk.remote? }.should.raise(ArgumentError)
    end

    describe 'when a domain limit is specified in the configuration' do
      before do
        @domain = 'myhost'
        @config = WhiskeyDisk::Config.new
        @config.stub!(:domain_limit).and_return(@domain)
        @whiskey_disk.stub!(:config).and_return(@config)
      end
      
      it 'should return false if the provided domain is nil' do
        @whiskey_disk.remote?(nil).should == false
      end

      it 'should return false if the provided domain is the string "local"' do
        @whiskey_disk.remote?('local').should == false
      end

      it 'should return false if the provided domain matches the limit domain from the configuration' do
        @whiskey_disk.remote?(@domain).should == false
      end

      it 'should return false if the provided domain, ignoring any user@, matches the limit domain from the configuration' do
        @whiskey_disk.remote?("user@" + @domain).should == false
      end

      it 'should return true if the provided domain does not match the limit domain from the configuration' do
        @whiskey_disk.remote?('smeghost').should == true
      end
    end
    
    describe 'when no domain limit is specified in the configuration' do
      before do
        @config = WhiskeyDisk::Config.new
        @config.stub!(:domain_limit).and_return(nil)
        @whiskey_disk.stub!(:config).and_return(@config)
      end

      it 'should return false if the provided domain is nil' do
        @whiskey_disk.remote?(nil).should == false
      end
    
      it 'should return false if the provided domain is the string "local"' do
        @whiskey_disk.remote?('local').should == false
      end

      it 'should return true if the provided domain is non-empty' do
        @whiskey_disk.remote?('smeghost').should == true
      end
    end
  end
  
  describe 'determining if the deployment has a configuration repository' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      @whiskey_disk.configuration = @parameters
    end
    
    it 'should work without arguments' do
      lambda { @whiskey_disk.has_config_repo? }.should.not.raise(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { @whiskey_disk.has_config_repo?(:foo) }.should.raise(ArgumentError)
    end
    
    it 'should return true if the configuration includes a non-empty config_repository setting' do
      @parameters['config_repository'] = 'git://foo.git'
      @whiskey_disk.has_config_repo?.should == true
    end
    
    it 'should return false if the configuration includes a nil config_repository setting' do
      @parameters['config_repository'] = nil
      @whiskey_disk.has_config_repo?.should == false
    end
    
    it 'should return false if the configuration includes a blank config_repository setting' do
      @parameters['config_repository'] = ''
      @whiskey_disk.has_config_repo?.should == false
    end
  end
  
  describe 'enabling staleness checks' do
    it 'should ensure that staleness checks are activated' do
      @whiskey_disk.enable_staleness_checks
      @whiskey_disk.staleness_checks_enabled?.should == true      
    end
  end
  
  describe 'when checking staleness checks' do
    it 'should return false if staleness checks have not been enabled' do
      @whiskey_disk.staleness_checks_enabled?.should == false
    end
    
    it 'should return true if staleness checks have been enabled' do
      @whiskey_disk.enable_staleness_checks
      @whiskey_disk.staleness_checks_enabled?.should == true
    end
  end

  describe 'ensuring that the parent path for the main repository checkout is present' do
    before do
      @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo' }
    end
    
    it 'should fail if the deployment path is not specified' do
      @whiskey_disk.configuration = {}
      lambda { @whiskey_disk.ensure_main_parent_path_is_present }.should.raise
    end
    
    it 'should attempt to create the parent path for the repository' do
      @whiskey_disk.ensure_main_parent_path_is_present
      @whiskey_disk.buffer.last.should.match(%r{mkdir -p /path/to/main})
      @whiskey_disk.buffer.last.should.not.match(%r{/path/to/main/repo})
    end
  end

  describe 'ensuring that the parent path for the configuration repository checkout is present' do
    before do
      @whiskey_disk.configuration = { 'deploy_config_to' => '/path/to/config/repo' }
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      @whiskey_disk.configuration = {}
      lambda { @whiskey_disk.ensure_config_parent_path_is_present }.should.raise
    end
    
    it 'should attempt to create the parent path for the repository' do
      @whiskey_disk.ensure_config_parent_path_is_present
      @whiskey_disk.buffer.last.should.match(%r{mkdir -p /path/to/config})
      @whiskey_disk.buffer.last.should.not.match(%r{/path/to/config/repo})
    end
  end
  
  describe 'checking out the main repository' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'repository' => 'git@ogtastic.com:whiskey_disk.git' }
      @whiskey_disk.configuration = @parameters
    end
    
    it 'should fail if the deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_to' => nil)
      lambda { @whiskey_disk.checkout_main_repository }.should.raise
    end
    
    it 'should fail if the repository is not specified' do
      @whiskey_disk.configuration = @parameters.merge('repository' => nil)
      lambda { @whiskey_disk.checkout_main_repository }.should.raise
    end
    
    it 'should work from the main repository checkout parent path' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main[^/]})
    end
      
    it 'should attempt to clone the main repository to the repository checkout path' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{clone #{@parameters['repository']} repo})
    end
    
    it 'should make the main repository clone conditional on the lack of a main repository checkout' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{if \[ -e #{@parameters['deploy_to']} \]; then .*; fi})
    end
    
    it 'should do a branch creation checkout of the master branch when no branch is specified' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout -b master origin/master})
    end
    
    it 'should fall back to a regular checkout of the master branch with origin branch when no branch is specified' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout master origin/master})
    end
    
    it 'should fall back to a regular checkout of the master branch when no branch is specified' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout master origin/master \|\| git checkout master})
    end
    
    it 'should do a branch creation checkout of the specified branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout -b production origin/production})
    end

    it 'should fall back to a regular checkout of the specified branch with origin branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout production origin/production})
    end

    it 'should fall back to a regular checkout of the specified branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout production origin/production \|\| git checkout production})
    end

    it 'should do branch checkouts from the repository path' do
      @whiskey_disk.checkout_main_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo && git checkout})      
    end
  end
  
  describe 'checking out the configuration repository' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo', 'config_repository' => 'git@ogtastic.com:config.git' }
      @whiskey_disk.configuration = @parameters
    end

    it 'should fail if the configuration deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { @whiskey_disk.checkout_configuration_repository }.should.raise
    end

    it 'should fail if the configuration repository is not specified' do
      @whiskey_disk.configuration = @parameters.merge('config_repository' => nil)
      lambda { @whiskey_disk.checkout_configuration_repository }.should.raise
    end

    it 'should work from the configuration repository checkout parent path' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/config[^/]})
    end

    it 'should attempt to clone the configuration repository to the repository checkout path' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{clone #{@parameters['config_repository']} repo})
    end
    
    it 'should make the configuration repository clone conditional on the lack of a main repository checkout' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{if \[ -e #{@parameters['deploy_config_to']} \]; then .*; fi})
    end

    it 'should do a branch creation checkout of the master branch when no branch is specified' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout -b master origin/master})
    end
    
    it 'should fall back to a regular checkout of the master branch with origin branch when no branch is specified' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout master origin/master})
    end
    
    it 'should fall back to a regular checkout of the master branch when no branch is specified' do
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout master origin/master \|\| git checkout master})
    end
    
    it 'should do a branch creation checkout of the specified branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout -b production origin/production})
    end

    it 'should fall back to a regular checkout of the specified branch with origin branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout production origin/production})
    end
    
    it 'should fall back to a regular checkout of the specified branch when a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
      @whiskey_disk.checkout_configuration_repository
      @whiskey_disk.buffer.join(' ').should.match(%r{\|\| git checkout production origin/production \|\| git checkout production})
    end
    
  end
  
  describe 'updating the main repository checkout' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      @whiskey_disk.configuration = @parameters
    end
    
    it 'should fail if the deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_to' => nil)
      lambda { @whiskey_disk.update_main_repository_checkout }.should.raise
    end
    
    it 'should work from the main repository checkout path' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    it 'should clear out any existing git changes data' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{rm -f /path/to/main/repo/.whiskey_disk_git_changes})
    end
        
    it 'should capture the current git HEAD ref for the current branch' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{ml=\`git log -1 --pretty=format:%H\`})
    end
    
    it 'should capture the current git HEAD ref for the current branch if no branch is specified' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{ml=\`git log -1 --pretty=format:%H\`})
    end
    
    it 'should attempt to fetch only the master branch from the origin if no branch is specified' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/master:refs/remotes/origin/master})
    end
    
    it 'should attempt to fetch the specified branch from the origin if a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/production:refs/remotes/origin/production})
    end

    it 'should work from the default branch if no branch is specified' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout master})
    end

    it 'should work from the specified branch if one is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git checkout production})
    end

    it 'should attempt to reset the master branch from the origin if no branch is specified' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end
    
    it 'should attempt to reset the specified branch from the origin if a branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git reset --hard origin/production})
    end
    
    it 'should collect git changes data' do
      @whiskey_disk.update_main_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git diff --name-only \$\{ml\}\.\.HEAD > /path/to/main/repo/\.whiskey_disk_git_changes})
    end
  end
  
  describe 'updating the configuration repository checkout' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo', 'deploy_to' => '/path/to/main/repo' }
      @whiskey_disk.configuration = @parameters
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { @whiskey_disk.update_configuration_repository_checkout }.should.raise
    end
    
    it 'should work from the main repository checkout path' do
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/config/repo})
    end
    
    it 'should clear out any existing rsync changes data' do
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{rm -f /path/to/main/repo/.whiskey_disk_rsync_changes})
    end
    
    it 'should attempt to fetch only the master branch from the origin if no configuration branch is specified' do
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/master:refs/remotes/origin/master})
    end
    
    it 'should attempt to fetch the specified branch from the origin if a configuration branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/production:refs/remotes/origin/production})
    end
    
    it 'should attempt to reset the master branch from the origin if no configuration branch is specified' do
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end

    it 'should attempt to reset the master branch from the origin if no configuration branch is specified' do
      @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
      @whiskey_disk.update_configuration_repository_checkout
      @whiskey_disk.buffer.join(' ').should.match(%r{git reset --hard origin/production})
    end
  end
  
  describe 'refreshing the configuration' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 
                      'deploy_config_to' => '/path/to/config/repo',
                      'environment' => 'production',
                      'config_repository' => 'git@git://foo.bar.git',
                      'config_branch' => 'master',
                      'config_target' => 'staging',
                      'project' => 'whiskey_disk' }
      @whiskey_disk.configuration = @parameters
    end

    it 'should fail if the main deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_to' => nil)
      lambda { @whiskey_disk.refresh_configuration }.should.raise
    end
  
    it 'should fail if the configuration deployment path is not specified' do
      @whiskey_disk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { @whiskey_disk.refresh_configuration }.should.raise
    end
  
    it 'should fail if no project name was specified' do
      @whiskey_disk.configuration = @parameters.merge('project' => 'unnamed_project')
      lambda { @whiskey_disk.refresh_configuration }.should.raise      
    end
  
    it 'should use rsync to overlay the configuration checkout for the project in the config target onto the main checkout' do
      @whiskey_disk.refresh_configuration
      @whiskey_disk.buffer.last.should.match(%r{rsync.* /path/to/config/repo/whiskey_disk/staging/ /path/to/main/repo/})
    end
    
    it 'should capture rsync change data' do
      @whiskey_disk.refresh_configuration
      @whiskey_disk.buffer.last.should.match(%r{rsync.* --log-format="%t \[%p\] %i %n".*> /path/to/main/repo/.whiskey_disk_rsync_changes})
    end
  end

  describe 'running post setup hooks' do
    before do
      @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo' }
      ENV['debug'] = nil
    end
    
    it 'should fail if the deployment path is not specified' do
      @whiskey_disk.configuration = {}
      lambda { @whiskey_disk.run_post_setup_hooks }.should.raise
    end
    
    it 'should work from the main checkout directory' do
      @whiskey_disk.run_post_setup_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    describe 'when a post setup script is specified' do
      describe 'and the script path does not start with a "/"' do      
        before do
          @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_setup_script' => 'path/to/setup/script', 'rake_env' => { 'FOO' => 'BAR' }  }
        end
      
        it 'should cd to the deploy_to path prior to running the script' do
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo;.*bash  /path/to/main/repo/path/to/setup/script})
        end

        it 'should attempt to run the post setup script with the deployment path prepended' do        
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/main/repo/path/to/setup/script})
        end
      
        it 'should pass any environment variables when running the post setup script' do
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{FOO='BAR'  bash  /path/to/main/repo/path/to/setup/script})      
        end

        it 'should enable shell verbosity when debugging is enabled' do
          ENV['debug'] = 'true'
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash -x /path/to/main/repo/path/to/setup/script})      
        end

        it 'should disable shell verbosity when debugging is not enabled' do
          ENV['debug'] = 'false'
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/main/repo/path/to/setup/script})      
        end
      end
      
      describe 'and the script path starts with a "/"' do
        before do
          @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_setup_script' => '/path/to/setup/script', 'rake_env' => { 'FOO' => 'BAR' } }
        end

        it 'should cd to the deploy_to path prior to running the script' do
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo;.*bash  /path/to/setup/script})
        end
      
        it 'should run the post setup script using its absolute path' do
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/setup/script})
        end

        it 'should pass any environment variables when running the post setup script' do
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{FOO='BAR'  bash  /path/to/setup/script})      
        end

        it 'should enable shell verbosity when debugging is enabled' do
          ENV['debug'] = 'true'
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash -x /path/to/setup/script})      
        end

        it 'should disable shell verbosity when debugging is not enabled' do
          ENV['debug'] = 'false'
          @whiskey_disk.run_post_setup_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/setup/script})      
        end
      end
    end
        
    it 'should attempt to run the post setup rake tasks' do
      @whiskey_disk.run_post_setup_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{rake.*deploy:post_setup})
    end
    
    it 'should use the same environment when running the rake tasks' do
      @whiskey_disk.run_post_setup_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{to=#{@env}})      
    end
    
    it 'should make the post setup rake tasks conditional on the presence of a Rakefile in the deployment path' do      
      @whiskey_disk.run_post_setup_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/Rakefile \]; then .*; fi})
    end
    
    it 'should make the post setup rake tasks conditional on the deploy:post_setup rake task being defined' do
      @whiskey_disk.run_post_setup_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{rakep=\`.*rake -P\` && if \[\[ \`echo "\$\{rakep\}" | grep deploy:post_setup\` != "" \]\];})      
    end

    it 'should ensure that any rake ENV variable are set when checking for deploy:post_setup tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      @whiskey_disk.configuration = @parameters
      @whiskey_disk.run_post_setup_hooks
      @parameters['rake_env'].each_pair do |k,v|
        @whiskey_disk.buffer.join(' ').should.match(%r{#{k}='#{v}' .*rake -P})
      end
    end
    
    it 'should set any rake_env variables when running the rake tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      @whiskey_disk.configuration = @parameters
      @whiskey_disk.run_post_setup_hooks
      @parameters['rake_env'].each_pair do |k,v|
        @whiskey_disk.buffer.join(' ').should.match(%r{#{k}='#{v}' })
      end
    end
  end
  
  describe 'running post deployment hooks' do
    before do
      @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo' }
      ENV['debug'] = nil
    end
    
    it 'should fail if the deployment path is not specified' do
      @whiskey_disk.configuration = {}
      lambda { @whiskey_disk.run_post_deploy_hooks }.should.raise
    end
    
    it 'should work from the main checkout directory' do
      @whiskey_disk.run_post_deploy_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    describe 'when a post deployment script is specified' do
      describe 'and the script path does not start with a "/"' do      
        before do
          @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_deploy_script' => 'path/to/deployment/script', 'rake_env' => { 'FOO' => 'BAR' }  }
        end
      
        it 'should cd to the deploy_to path prior to running the script' do
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo;.*bash  /path/to/main/repo/path/to/deployment/script})
        end

        it 'should attempt to run the post deployment script with the deployment path prepended' do        
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/main/repo/path/to/deployment/script})
        end
        
        it 'should pass any environment variables when running the post deploy script' do
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{FOO='BAR'  bash  /path/to/main/repo/path/to/deployment/script})      
        end

        it 'should enable shell verbosity when debugging is enabled' do
          ENV['debug'] = 'true'
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash -x /path/to/main/repo/path/to/deployment/script})
        end

        it 'should disable shell verbosity when debugging is not enabled' do
          ENV['debug'] = 'false'
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/main/repo/path/to/deployment/script})
        end
      end
      
      describe 'and the script path starts with a "/"' do
        before do
          @whiskey_disk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_deploy_script' => '/path/to/deployment/script', 'rake_env' => { 'FOO' => 'BAR' }  }
        end

        it 'should cd to the deploy_to path prior to running the script' do
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{cd /path/to/main/repo;.*bash  /path/to/deployment/script})
        end

        it 'should attempt to run the post deployment script using its absolute path' do        
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/deployment/script})
        end
      
        it 'should pass any environment variables when running the post deploy script' do
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{FOO='BAR'  bash  /path/to/deployment/script})      
        end

        it 'should enable shell verbosity when debugging is enabled' do
          ENV['debug'] = 'true'
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash -x /path/to/deployment/script})      
        end

        it 'should disable shell verbosity when debugging is not enabled' do
          ENV['debug'] = 'false'
          @whiskey_disk.run_post_deploy_hooks
          @whiskey_disk.buffer.join(' ').should.match(%r{bash  /path/to/deployment/script})      
        end
      end
    end
        
    it 'should attempt to run the post deployment rake tasks' do
      @whiskey_disk.run_post_deploy_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{rake.*deploy:post_deploy})
    end
    
    it 'should use the same environment when running the rake tasks' do
      @whiskey_disk.run_post_deploy_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{to=#{@env}})      
    end

    it 'should make the post deployment rake tasks conditional on the presence of a Rakefile in the deployment path' do      
      @whiskey_disk.run_post_deploy_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/Rakefile \]; then .*; fi})
    end
    
    it 'should make the post deployment rake tasks conditional on the deploy:post_deploy rake task being defined' do
      @whiskey_disk.run_post_deploy_hooks
      @whiskey_disk.buffer.join(' ').should.match(%r{rakep=\`.*rake -P\` && if \[\[ \`echo "\$\{rakep\}" | grep deploy:post_deploy\` != "" \]\];})      
    end

    it 'should ensure that any rake ENV variable are set when checking for deploy:post_setup tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      @whiskey_disk.configuration = @parameters
      @whiskey_disk.run_post_deploy_hooks
      @parameters['rake_env'].each_pair do |k,v|
        @whiskey_disk.buffer.join(' ').should.match(%r{#{k}='#{v}' .*rake -P})
      end
    end
    
    it 'should set any rake_env variables when running the rake tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      @whiskey_disk.configuration = @parameters
      @whiskey_disk.run_post_deploy_hooks
      @parameters['rake_env'].each_pair do |k,v|
        @whiskey_disk.buffer.join(' ').should.match(%r{#{k}='#{v}' })
      end
    end
  end
  
  describe 'bundling up buffered commands for execution' do
    describe 'when staleness checks are disabled' do
      it 'should return an empty string if there are no commands' do
        @whiskey_disk.bundle.should == ''
      end

      it 'should wrap each command with {} and join with &&s' do
        @whiskey_disk.enqueue("cd foo/bar/baz || true")
        @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
        @whiskey_disk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
      end

      it 'should not wrap the bundled commands inside a staleness check' do
        @whiskey_disk.enqueue("cd foo/bar/baz || true")
        @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
        @whiskey_disk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
      end
    end

    describe 'when staleness checks are enabled' do
      before do
        @whiskey_disk.enable_staleness_checks
      end
      
      describe 'but not we are not configured for staleness checks on this deployment' do
        before do
          ENV['check'] = nil
        end
        
        it 'should return an empty string if there are no commands' do
          @whiskey_disk.bundle.should == ''
        end

        it 'should wrap each command with {} and join with &&s' do
          @whiskey_disk.enqueue("cd foo/bar/baz || true")
          @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
          @whiskey_disk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
        end

        it 'should not wrap the bundled commands inside a staleness check' do
          @whiskey_disk.enqueue("cd foo/bar/baz || true")
          @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
          @whiskey_disk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
        end       
      end
      
      describe 'and we are configured for staleness checks on this deployment' do
        before do
          ENV['check'] = 'true'
        end
        
        describe 'when no configuration repository is in use' do
          before do
            @deploy_to = '/path/to/main/repo'
            @repository = 'git@git://foo.bar.git'
            @parameters = { 'deploy_to' => @deploy_to, 'repository' => @repository }
            @whiskey_disk.configuration = @parameters
            @whiskey_disk.enable_staleness_checks
          end
          
          it 'should return an empty string if there are no commands' do
            @whiskey_disk.bundle.should == ''
          end

          it 'should wrap each command with {} and join with &&s' do
            @whiskey_disk.enqueue("cd foo/bar/baz || true")
            @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }")))
          end

          it 'should wrap the bundled commands inside a staleness check which checks only the main repo for staleness' do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("if [[ $ml != ${mr%%\t*} ]] ; then { COMMAND ; }")))
          end
          
          it 'should add a notice message for when the repository is not stale' do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("then { COMMAND ; }; else echo \"No changes to deploy.\"; fi")))            
          end
          
          it "should query the head of the main checkout's current branch if no branch is specified" do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head of the main checkout's current branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head on the main repository's master branch if no branch is specified" do            
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the main repository's specified branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/production\`;")))
          end
          
          it 'should not check a configuration repository for staleness' do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.not.match(/c[lr]=/)
          end
        end
      
        describe 'when a configuration repository is in use' do
          before do
            @deploy_to = '/path/to/main/repo'
            @repository = 'git@git://foo.bar.git'
            @deploy_config_to = '/path/to/config/repo'
            @config_repository = 'git@git://foo.bar-config.git'
            @parameters = { 
              'deploy_to' => @deploy_to, 'repository' => @repository,
              'deploy_config_to' => @deploy_config_to, 'config_repository' => @config_repository
            }
            @whiskey_disk.configuration = @parameters
            @whiskey_disk.enable_staleness_checks
          end
          
          it 'should return an empty string if there are no commands' do
            @whiskey_disk.bundle.should == ''
          end

          it 'should wrap each command with {} and join with &&s' do
            @whiskey_disk.enqueue("cd foo/bar/baz || true")
            @whiskey_disk.enqueue("rsync -avz --progress /yer/mom /yo/")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }")))
          end

          it 'should wrap the bundled commands inside a staleness check which checks both main and config repos for staleness' do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("if [[ $ml != ${mr%%\t*} ]] || [[ $cl != ${cr%%\t*} ]]; then { COMMAND ; }")))
          end
          
          it 'should add a notice message for when the repositories are not stale' do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("then { COMMAND ; }; else echo \"No changes to deploy.\"; fi")))            
          end
          
          it "should query the head of the main checkout's current branch if no branch is specified" do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head of the main checkout's current branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head on the main repository's master branch if no branch is specified" do            
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the main repository's specified branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/production\`;")))
          end
          
          it "should query the head of the config checkout's current branch if no branch is specified" do
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_config_to}; cl=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head of the config checkout's current branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_config_to}; cl=\`git log -1 --pretty=format:%H\`;")))
          end
          
          it "should query the head on the config repository's master branch if no branch is specified" do            
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cr=\`git ls-remote #{@config_repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the config repository's specified branch if a branch is specified" do
            @whiskey_disk.configuration = @parameters.merge({'config_branch' => 'production'})
            @whiskey_disk.enable_staleness_checks
            @whiskey_disk.enqueue("COMMAND")
            @whiskey_disk.bundle.should.match(Regexp.new(Regexp.escape("cr=\`git ls-remote #{@config_repository} refs/heads/production\`;")))
          end
        end
      end
    end
  end
  
  describe 'determining if a domain is of interest to us' do
    before do
      @config = WhiskeyDisk::Config.new
      @config.stub!(:domain_limit).and_return(false)
      @whiskey_disk.stub!(:config).and_return(@config)
    end
    
    it 'should allow specifying a domain' do
      lambda { @whiskey_disk.domain_of_interest?(:domain) }.should.not.raise(ArgumentError)
    end
    
    it 'should require a domain' do
      lambda { @whiskey_disk.domain_of_interest? }.should.raise(ArgumentError)      
    end
    
    it 'should return true when our configuration does not specify a domain limit' do
      @config.stub!(:domain_limit).and_return(false)
      @whiskey_disk.domain_of_interest?('somedomain').should == true
    end
    
    it 'should return true when the specified domain matches the configuration domain limit' do
      @config.stub!(:domain_limit).and_return('somedomain')
      @whiskey_disk.domain_of_interest?('somedomain').should == true      
    end
    
    it 'should return true when the specified domain matches the configuration domain limit, with a prepended "user@"' do
      @config.stub!(:domain_limit).and_return('somedomain')
      @whiskey_disk.domain_of_interest?('user@somedomain').should == true      
    end    
    
    it 'should return false when the specified domain does not match the configuration domain limit' do
      @config.stub!(:domain_limit).and_return('otherdomain')
      @whiskey_disk.domain_of_interest?('somedomain').should == false  
    end
  end

  describe 'flushing changes' do
    before do
      @cmd = 'ls'
      @domains = [ { :name => 'ogc@ogtastic.com' }, { :name => 'foo@example.com' }, { :name => 'local' } ]
      @whiskey_disk.configuration = { 'domain' => @domains }
      @whiskey_disk.stub!(:domain_of_interest?).and_return(true)
      @whiskey_disk.stub!(:bundle).and_return(@cmd)
      @whiskey_disk.stub!(:system)
      @whiskey_disk.stub!(:puts)
    end
          
    it 'should fail if the domain path is not specified' do
      @whiskey_disk.configuration = {}
      lambda { @whiskey_disk.flush}.should.raise
    end

    it 'should use "run" to issue commands for all remote domains' do
      @whiskey_disk.should.receive(:run).with({ :name => 'ogc@ogtastic.com' }, @cmd)
      @whiskey_disk.should.receive(:run).with({ :name => 'foo@example.com' }, @cmd)
      @whiskey_disk.flush
    end
    
    it 'should use "shell" to issue commands for any local domains' do
      @whiskey_disk.should.receive(:shell).with({ :name => 'local' }, @cmd)
      @whiskey_disk.flush      
    end    

    it 'should not issue a command via run for a remote domain which is not of interest' do
      @whiskey_disk.stub!(:domain_of_interest?).with('ogc@ogtastic.com').and_return(false)
      @whiskey_disk.should.not.receive(:run).with({ :name => 'ogc@ogtastic.com' }, @cmd)
      @whiskey_disk.flush
    end

    it 'should not issue a command via shell for a local domain which is not of interest' do
      @whiskey_disk.stub!(:domain_of_interest?).with('local').and_return(false)
      @whiskey_disk.should.not.receive(:shell).with({ :name => 'local' }, @cmd)
      @whiskey_disk.flush
    end
  end
  
  describe 'when running a command string locally' do
    before do
      @domain_name = 'local'
      @domain = { :name => @domain_name }
      @whiskey_disk.configuration = { 'domain' => [ @domain ] }
      @whiskey_disk.stub!(:system)
      @whiskey_disk.stub!(:puts)
    end
    
    it 'should accept a domain and a command string' do
      lambda { @whiskey_disk.shell(@domain, 'ls') }.should.not.raise(ArgumentError)
    end
    
    it 'should require a domain and a command string' do
      lambda { @whiskey_disk.shell(@domain) }.should.raise(ArgumentError)
    end
    
    describe 'when debugging is enabled' do
      before { ENV['debug'] = 'true' }

      it 'should pass the string to the shell with verbosity enabled' do
        @whiskey_disk.should.receive(:system).with('bash', '-c', "set -x; ls")
        @whiskey_disk.shell(@domain, 'ls')
      end
      
      it 'should include domain role settings when the domain has roles' do
        @domain = { :name => @domain_name, :roles => [ 'web', 'db' ] }
        @whiskey_disk.configuration = { 'domain' => [ @domain ] }
        @whiskey_disk.should.receive(:system).with('bash', '-c', "set -x; export WD_ROLES='web:db'; ls")
        @whiskey_disk.shell(@domain, 'ls')        
      end
    end
    
    describe 'when debugging is not enabled' do
      before { ENV['debug'] = 'false' }

      it 'should pass the string to the shell without verbosity enabled' do
        @whiskey_disk.should.receive(:system).with('bash', '-c', "ls")
        @whiskey_disk.shell(@domain, 'ls')
      end
      
      it 'should include domain role settings when the domain has roles' do
        @domain = { :name => @domain_name, :roles => [ 'web', 'db' ] }
        @whiskey_disk.configuration = { 'domain' => [ @domain ] }
        @whiskey_disk.should.receive(:system).with('bash', '-c', "export WD_ROLES='web:db'; ls")
        @whiskey_disk.shell(@domain, 'ls')        
      end
    end
  end

  describe 'when running a command string remotely' do
    before do
      @domain_name = 'ogc@ogtastic.com'
      @domain = { :name => @domain_name }
      @whiskey_disk.configuration = { 'domain' => [ @domain ] }
      @whiskey_disk.stub!(:system)
      @whiskey_disk.stub!(:puts)
    end
    
    it 'should accept a domain and a command string' do
      lambda { @whiskey_disk.run(@domain, 'ls') }.should.not.raise(ArgumentError)
    end
    
    it 'should require a domain and a command string' do
      lambda { @whiskey_disk.run(@domain) }.should.raise(ArgumentError)
    end

    describe "building a command" do
      it 'should include domain role settings when the domain has roles' do
        @domain = { :name => @domain_name, :roles => [ 'web', 'db' ] }
        @whiskey_disk.configuration = { 'domain' => [ @domain ] }
        @whiskey_disk.build_command(@domain, 'ls').should.match /export WD_ROLES='web:db'; ls/
      end
    end

    describe 'when debugging is enabled' do
      before { ENV['debug'] = 'true' }

      it 'should pass the string to ssh for the domain, with verbosity enabled' do
        @whiskey_disk.should.receive(:system).with('ssh', '-v', @domain_name, "set -x; ls")
        @whiskey_disk.run(@domain, 'ls')
      end
    end

    describe 'when debugging is not enabled' do
      before { ENV['debug'] = 'false' }

      it 'should pass the string to ssh for the domain, with verbosity disabled' do
        @whiskey_disk.should.receive(:system).with('ssh', @domain_name, "ls")
        @whiskey_disk.run(@domain, 'ls')
      end
    end
  end

  describe 'determining if all the deployments succeeded' do
    it 'should work without arguments' do
      lambda { @whiskey_disk.success? }.should.not.raise(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { @whiskey_disk.success?(:foo) }.should.raise(ArgumentError)
    end
    
    it 'should return true if there are no results recorded' do
      @whiskey_disk.success?.should.be.true
    end
    
    it 'should return true if all recorded results have true statuses' do
      @whiskey_disk.record_result('1', true)
      @whiskey_disk.record_result('2', true)
      @whiskey_disk.record_result('3', true)
      @whiskey_disk.success?.should.be.true
    end
    
    it 'should return false if any recorded result has a false status' do
      @whiskey_disk.record_result('1', true)
      @whiskey_disk.record_result('2', false)
      @whiskey_disk.record_result('3', true)
      @whiskey_disk.success?.should.be.false      
    end
  end
  
  describe 'summarizing the results of a run' do
    before do
      @whiskey_disk.stub!(:puts)
    end
    
    it 'should work without arguments' do
      lambda { @whiskey_disk.summarize }.should.not.raise(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { @whiskey_disk.summarize(:foo) }.should.raise(ArgumentError)      
    end
    
    it 'should output a no runs message when no results are recorded' do
      @whiskey_disk.should.receive(:puts).with('No deployments to report.')
      @whiskey_disk.summarize
    end
    
    describe 'and there are results recorded' do
      before do
        @whiskey_disk.record_result('foo@bar.com', false)
        @whiskey_disk.record_result('ogc@ogtastic.com', true)
        @whiskey_disk.record_result('user@example.com', true)
      end
      
      it 'should output a status line for each recorded deployment run' do
        @whiskey_disk.should.receive(:puts).with('foo@bar.com => failed.')
        @whiskey_disk.should.receive(:puts).with('ogc@ogtastic.com => succeeded.')
        @whiskey_disk.should.receive(:puts).with('user@example.com => succeeded.')
        @whiskey_disk.summarize
      end
    
      it 'should output a summary line including the total runs, count of failures and count of successes.' do
        @whiskey_disk.should.receive(:puts).with('Total: 3 deployments, 2 successes, 1 failure.')        
        @whiskey_disk.summarize
      end
    end
  end
end
