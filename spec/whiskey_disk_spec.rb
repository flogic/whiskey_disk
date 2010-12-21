require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk'))
require 'rake'

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

describe 'WhiskeyDisk' do
  describe 'determining if the deployment is remote' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk.configuration = @parameters
    end
    
    it 'should work without arguments' do
      lambda { WhiskeyDisk.remote? }.should.not.raise(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { WhiskeyDisk.remote?(:foo) }.should.raise(ArgumentError)
    end
    
    it 'should return true if the configuration includes a non-empty domain setting' do
      @parameters['domain'] = 'smeghost'
      WhiskeyDisk.remote?.should == true
    end
    
    it 'should return false if the configuration includes a nil domain setting' do
      @parameters['domain'] = nil
      WhiskeyDisk.remote?.should == false
    end
    
    it 'should return false if the configuration includes a blank domain setting' do
      @parameters['domain'] = ''
      WhiskeyDisk.remote?.should == false
    end
    
    it 'should return false if the configuration includes an empty list of domain settings' do
      @parameters['domain'] = []
      WhiskeyDisk.remote?.should == false      
    end
    
    it 'should return false if the configuration includes a list of blank or nil domain settings' do
      @parameters['domain'] = [nil, '', nil, '']
      WhiskeyDisk.remote?.should == false      
    end
  end
  
  describe 'determining if the deployment has a configuration repository' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk.configuration = @parameters
    end
    
    it 'should work without arguments' do
      lambda { WhiskeyDisk.has_config_repo? }.should.not.raise(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { WhiskeyDisk.has_config_repo?(:foo) }.should.raise(ArgumentError)
    end
    
    it 'should return true if the configuration includes a non-empty config_repository setting' do
      @parameters['config_repository'] = 'git://foo.git'
      WhiskeyDisk.has_config_repo?.should == true
    end
    
    it 'should return false if the configuration includes a nil config_repository setting' do
      @parameters['config_repository'] = nil
      WhiskeyDisk.has_config_repo?.should == false
    end
    
    it 'should return false if the configuration includes a blank config_repository setting' do
      @parameters['config_repository'] = ''
      WhiskeyDisk.has_config_repo?.should == false
    end
  end
  
  describe 'enabling staleness checks' do
    it 'should ensure that staleness checks are activated' do
      WhiskeyDisk.reset
      WhiskeyDisk.enable_staleness_checks
      WhiskeyDisk.staleness_checks_enabled?.should == true      
    end
  end
  
  describe 'when checking staleness checks' do
    it 'should return false if staleness checks have not been enabled' do
      WhiskeyDisk.reset
      WhiskeyDisk.staleness_checks_enabled?.should == false
    end
    
    it 'should return true if staleness checks have been enabled' do
      WhiskeyDisk.reset
      WhiskeyDisk.enable_staleness_checks
      WhiskeyDisk.staleness_checks_enabled?.should == true
    end
  end

  describe 'ensuring that the parent path for the main repository checkout is present' do
    before do
      WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo' }
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk.configuration = {}
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
      WhiskeyDisk.configuration = { 'deploy_config_to' => '/path/to/config/repo' }
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk.configuration = {}
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
      WhiskeyDisk.configuration = @parameters
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_to' => nil)
      lambda { WhiskeyDisk.checkout_main_repository }.should.raise
    end
    
    it 'should fail if the repository is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('repository' => nil)
      lambda { WhiskeyDisk.checkout_main_repository }.should.raise
    end
    
    it 'should work from the main repository checkout parent path' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/main})
      WhiskeyDisk.buffer.join(' ').should.not.match(%r{cd /path/to/main/repo})
    end
      
    it 'should attempt to shallow clone the main repository to the repository checkout path' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{clone --depth 1 #{@parameters['repository']} repo})
    end
    
    it 'should make the main repository clone conditional on the lack of a main repository checkout' do
      WhiskeyDisk.checkout_main_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e #{@parameters['deploy_to']} \]; then .*; fi})
    end
  end
  
  describe 'checking out the configuration repository' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo', 'config_repository' => 'git@ogtastic.com:config.git' }
      WhiskeyDisk.configuration = @parameters
    end

    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { WhiskeyDisk.checkout_configuration_repository }.should.raise
    end

    it 'should fail if the configuration repository is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('config_repository' => nil)
      lambda { WhiskeyDisk.checkout_configuration_repository }.should.raise
    end

    it 'should work from the configuration repository checkout parent path' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/config})
      WhiskeyDisk.buffer.join(' ').should.not.match(%r{cd /path/to/config/repo})
    end

    it 'should attempt to shallow clone the configuration repository to the repository checkout path' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{clone --depth 1 #{@parameters['config_repository']} repo})
    end
    
    it 'should make the configuration repository clone conditional on the lack of a main repository checkout' do
      WhiskeyDisk.checkout_configuration_repository
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e #{@parameters['deploy_config_to']} \]; then .*; fi})
    end
  end
  
  describe 'updating the main repository checkout' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo' }
      WhiskeyDisk.configuration = @parameters
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_to' => nil)
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
      WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/production:refs/remotes/origin/production})
    end

    it 'should attempt to reset the master branch from the origin if no branch is specified' do
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end
    
    it 'should attempt to reset the specified branch from the origin if a branch is specified' do
      WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
      WhiskeyDisk.update_main_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/production})
    end
  end
  
  describe 'updating the configuration repository checkout' do
    before do
      @parameters = { 'deploy_config_to' => '/path/to/config/repo' }
      WhiskeyDisk.configuration = @parameters
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { WhiskeyDisk.update_configuration_repository_checkout }.should.raise
    end
    
    it 'should work from the main repository checkout path' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/config/repo})
    end
    
    it 'should attempt to fetch only the master branch from the origin if no configuration branch is specified' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/master:refs/remotes/origin/master})
    end
    
    it 'should attempt to fetch the specified branch from the origin if a configuration branch is specified' do
      WhiskeyDisk.configuration = @parameters.merge({'config_branch' => 'production'})
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git fetch origin \+refs/heads/production:refs/remotes/origin/production})
    end
    
    it 'should attempt to reset the master branch from the origin if no configuration branch is specified' do
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/master})
    end

    it 'should attempt to reset the master branch from the origin if no configuration branch is specified' do
      WhiskeyDisk.configuration = @parameters.merge({'config_branch' => 'production'})
      WhiskeyDisk.update_configuration_repository_checkout
      WhiskeyDisk.buffer.join(' ').should.match(%r{git reset --hard origin/production})
    end
  end
  
  describe 'refreshing the configuration' do
    before do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 
                      'deploy_config_to' => '/path/to/config/repo',
                      'environment' => 'production',
                      'config_repository' => 'git@git://foo.bar.git',
                      'config_branch' => 'master',
                      'project' => 'whiskey_disk' }
      WhiskeyDisk.configuration = @parameters
    end

    it 'should fail if the main deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_to' => nil)
      lambda { WhiskeyDisk.refresh_configuration }.should.raise
    end
    
    it 'should fail if the configuration deployment path is not specified' do
      WhiskeyDisk.configuration = @parameters.merge('deploy_config_to' => nil)
      lambda { WhiskeyDisk.refresh_configuration }.should.raise
    end
    
    it 'should fail if no project name was specified' do
      WhiskeyDisk.configuration = @parameters.merge('project' => 'unnamed_project')
      lambda { WhiskeyDisk.refresh_configuration }.should.raise      
    end
    
    it 'should use rsync to overlay the configuration checkout for the project in the configured environment onto the main checkout' do
      WhiskeyDisk.refresh_configuration
      WhiskeyDisk.buffer.last.should.match(%r{rsync.* /path/to/config/repo/whiskey_disk/production/ /path/to/main/repo/})
    end
  end
  
  describe 'running post setup hooks' do
    before do
      WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo' }
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk.configuration = {}
      lambda { WhiskeyDisk.run_post_setup_hooks }.should.raise
    end
    
    it 'should work from the main checkout directory' do
      WhiskeyDisk.run_post_setup_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    describe 'when a post setup script is specified' do
      describe 'and the script path does not start with a "/"' do      
        before do
          WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_setup_script' => '/path/to/setup/script' }
        end
      
        it 'should attempt to run the post setup script' do        
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x .*/path/to/setup/script})
        end
      
        it 'should use an absolute path to run the post setup script when the script path starts with a "/"' do
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x /path/to/setup/script})         
        end
        
        it 'should make the post setup script run conditional on the presence of the script' do
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/setup/script \]; then .*; fi})
        end
      end
      
      describe 'and the script path does not start with a "/"' do
        before do
          WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_setup_script' => 'path/to/setup/script' }
        end

        it 'should attempt to run the post setup script' do        
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x .*/path/to/setup/script})
        end
      
        it 'should use a path relative to the setupment path to run the post setup script' do
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x /path/to/main/repo/path/to/setup/script})
        end
        
        it 'should make the post setup script run conditional on the presence of the script' do
          WhiskeyDisk.run_post_setup_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/path/to/setup/script \]; then .*; fi})
        end
      end
    end
        
    it 'should attempt to run the post setup rake tasks' do
      WhiskeyDisk.run_post_setup_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{rake.*deploy:post_setup})
    end
    
    it 'should use the same environment when running the rake tasks' do
      WhiskeyDisk.run_post_setup_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{to=#{@env}})      
    end
    
    it 'should make the post setup rake tasks conditional on the presence of a Rakefile in the deployment path' do      
      WhiskeyDisk.run_post_setup_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/Rakefile \]; then .*; fi})
    end
    
    it 'should make the post setup rake tasks conditional on the deploy:post_setup rake task being defined' do
      WhiskeyDisk.run_post_setup_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[\[ \`rake -P | grep deploy:post_setup\` != "" \]\]; })      
    end

    it 'should ensure that any rake ENV variable are set when checking for deploy:post_setup tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      WhiskeyDisk.configuration = @parameters
      WhiskeyDisk.run_post_setup_hooks
      @parameters['rake_env'].each_pair do |k,v|
        WhiskeyDisk.buffer.join(' ').should.match(%r{#{k}='#{v}' .*rake -P})
      end
    end
    
    it 'should set any rake_env variables when running the rake tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      WhiskeyDisk.configuration = @parameters
      WhiskeyDisk.run_post_setup_hooks
      @parameters['rake_env'].each_pair do |k,v|
        WhiskeyDisk.buffer.join(' ').should.match(%r{#{k}='#{v}' })
      end
    end
  end
  
  describe 'running post deployment hooks' do
    before do
      WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo' }
    end
    
    it 'should fail if the deployment path is not specified' do
      WhiskeyDisk.configuration = {}
      lambda { WhiskeyDisk.run_post_deploy_hooks }.should.raise
    end
    
    it 'should work from the main checkout directory' do
      WhiskeyDisk.run_post_deploy_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{cd /path/to/main/repo})
    end
    
    describe 'when a post deployment script is specified' do
      describe 'and the script path does not start with a "/"' do      
        before do
          WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_deploy_script' => '/path/to/deployment/script' }
        end
      
        it 'should attempt to run the post deployment script' do        
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x .*/path/to/deployment/script})
        end
      
        it 'should use an absolute path to run the post deployment script when the script path starts with a "/"' do
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x /path/to/deployment/script})         
        end
        
        it 'should make the post deployment script run conditional on the presence of the script' do
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/deployment/script \]; then .*; fi})
        end
      end
      
      describe 'and the script path does not start with a "/"' do
        before do
          WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo', 'post_deploy_script' => 'path/to/deployment/script' }
        end

        it 'should attempt to run the post deployment script' do        
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x .*/path/to/deployment/script})
        end
      
        it 'should use a path relative to the deployment path to run the post deployment script' do
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{sh -x /path/to/main/repo/path/to/deployment/script})
        end
        
        it 'should make the post deployment script run conditional on the presence of the script' do
          WhiskeyDisk.run_post_deploy_hooks
          WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/path/to/deployment/script \]; then .*; fi})
        end
      end
    end
        
    it 'should attempt to run the post deployment rake tasks' do
      WhiskeyDisk.run_post_deploy_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{rake.*deploy:post_deploy})
    end
    
    it 'should use the same environment when running the rake tasks' do
      WhiskeyDisk.run_post_deploy_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{to=#{@env}})      
    end

    it 'should make the post deployment rake tasks conditional on the presence of a Rakefile in the deployment path' do      
      WhiskeyDisk.run_post_deploy_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[ -e /path/to/main/repo/Rakefile \]; then .*; fi})
    end
    
    it 'should make the post deployment rake tasks conditional on the deploy:post_deploy rake task being defined' do
      WhiskeyDisk.run_post_deploy_hooks
      WhiskeyDisk.buffer.join(' ').should.match(%r{if \[\[ \`rake -P | grep deploy:post_deploy\` != "" \]\]; })      
    end

    it 'should ensure that any rake ENV variable are set when checking for deploy:post_setup tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      WhiskeyDisk.configuration = @parameters
      WhiskeyDisk.run_post_deploy_hooks
      @parameters['rake_env'].each_pair do |k,v|
        WhiskeyDisk.buffer.join(' ').should.match(%r{#{k}='#{v}' .*rake -P})
      end
    end
    
    it 'should set any rake_env variables when running the rake tasks' do
      @parameters = { 'deploy_to' => '/path/to/main/repo', 'rake_env' => { 'RAILS_ENV' => 'production', 'FOO' => 'bar' } }
      WhiskeyDisk.configuration = @parameters
      WhiskeyDisk.run_post_deploy_hooks
      @parameters['rake_env'].each_pair do |k,v|
        WhiskeyDisk.buffer.join(' ').should.match(%r{#{k}='#{v}' })
      end
    end
  end
  
  describe 'flushing changes' do
    describe 'when running remotely' do
      before do
        WhiskeyDisk.configuration = { 'domain' => 'www.domain.com', 'deploy_to' => '/path/to/main/repo' }
        WhiskeyDisk.stub!(:bundle).and_return('command string')
        WhiskeyDisk.stub!(:run)
      end
      
      it 'should bundle the buffer of commands' do
        WhiskeyDisk.enqueue('x')
        WhiskeyDisk.enqueue('y')
        WhiskeyDisk.should.receive(:bundle)
        WhiskeyDisk.flush
      end
      
      it 'should use "run" to run all the bundled commands at once' do
        WhiskeyDisk.should.receive(:run).with('command string')
        WhiskeyDisk.flush
      end
    end
    
    describe 'when running locally' do
      before do
        WhiskeyDisk.configuration = { 'deploy_to' => '/path/to/main/repo' }
        WhiskeyDisk.stub!(:bundle).and_return('command string')
        WhiskeyDisk.stub!(:system)
      end
      
      it 'should bundle the buffer of commands' do
        WhiskeyDisk.enqueue('x')
        WhiskeyDisk.enqueue('y')
        WhiskeyDisk.should.receive(:bundle).and_return('command string')
        WhiskeyDisk.flush
      end
      
      it 'should use "system" to run all the bundled commands at once' do
        WhiskeyDisk.should.receive(:system).with('command string')
        WhiskeyDisk.flush
      end
    end
  end
  
  describe 'bundling up buffered commands for execution' do
    before do
      WhiskeyDisk.reset
    end
    
    describe 'when staleness checks are disabled' do
      it 'should return an empty string if there are no commands' do
        WhiskeyDisk.bundle.should == ''
      end

      it 'should wrap each command with {} and join with &&s' do
        WhiskeyDisk.enqueue("cd foo/bar/baz || true")
        WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
        WhiskeyDisk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
      end

      it 'should not wrap the bundled commands inside a staleness check' do
        WhiskeyDisk.enqueue("cd foo/bar/baz || true")
        WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
        WhiskeyDisk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
      end
    end

    describe 'when staleness checks are enabled' do
      before do
        WhiskeyDisk.enable_staleness_checks
      end
      
      describe 'but not we are not configured for staleness checks on this deployment' do
        before do
          ENV['check'] = nil
        end
        
        it 'should return an empty string if there are no commands' do
          WhiskeyDisk.bundle.should == ''
        end

        it 'should wrap each command with {} and join with &&s' do
          WhiskeyDisk.enqueue("cd foo/bar/baz || true")
          WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
          WhiskeyDisk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
        end

        it 'should not wrap the bundled commands inside a staleness check' do
          WhiskeyDisk.enqueue("cd foo/bar/baz || true")
          WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
          WhiskeyDisk.bundle.should == "{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }"
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
            WhiskeyDisk.configuration = @parameters
            WhiskeyDisk.enable_staleness_checks
          end
          
          it 'should return an empty string if there are no commands' do
            WhiskeyDisk.bundle.should == ''
          end

          it 'should wrap each command with {} and join with &&s' do
            WhiskeyDisk.enqueue("cd foo/bar/baz || true")
            WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }")))
          end

          it 'should wrap the bundled commands inside a staleness check which checks only the main repo for staleness' do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("if [[ $ml != ${mr%%\t*} ]] ; then { COMMAND ; }")))
          end
          
          it 'should add a notice message for when the repository is not stale' do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("then { COMMAND ; }; else echo \"No changes to deploy.\"; fi")))            
          end
          
          it "should query the head of the main checkout's master branch if no branch is specified" do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`cat .git/refs/heads/master\`;")))
          end
          
          it "should query the head of the main checkout's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`cat .git/refs/heads/production\`;")))
          end
          
          it "should query the head on the main repository's master branch if no branch is specified" do            
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the main repository's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/production\`;")))
          end
          
          it 'should not check a configuration repository for staleness' do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.not.match(/c[lr]=/)
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
            WhiskeyDisk.configuration = @parameters
            WhiskeyDisk.enable_staleness_checks
          end
          
          it 'should return an empty string if there are no commands' do
            WhiskeyDisk.bundle.should == ''
          end

          it 'should wrap each command with {} and join with &&s' do
            WhiskeyDisk.enqueue("cd foo/bar/baz || true")
            WhiskeyDisk.enqueue("rsync -avz --progress /yer/mom /yo/")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("{ cd foo/bar/baz || true ; } && { rsync -avz --progress /yer/mom /yo/ ; }")))
          end

          it 'should wrap the bundled commands inside a staleness check which checks both main and config repos for staleness' do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("if [[ $ml != ${mr%%\t*} ]] || [[ $cl != ${cr%%\t*} ]]; then { COMMAND ; }")))
          end
          
          it 'should add a notice message for when the repositories are not stale' do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("then { COMMAND ; }; else echo \"No changes to deploy.\"; fi")))            
          end
          
          it "should query the head of the main checkout's master branch if no branch is specified" do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`cat .git/refs/heads/master\`;")))
          end
          
          it "should query the head of the main checkout's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_to}; ml=\`cat .git/refs/heads/production\`;")))
          end
          
          it "should query the head on the main repository's master branch if no branch is specified" do            
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the main repository's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("mr=\`git ls-remote #{@repository} refs/heads/production\`;")))
          end
          
          it "should query the head of the config checkout's master branch if no branch is specified" do
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_config_to}; cl=\`cat .git/refs/heads/master\`;")))
          end
          
          it "should query the head of the config checkout's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'config_branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cd #{@deploy_config_to}; cl=\`cat .git/refs/heads/production\`;")))
          end
          
          it "should query the head on the config repository's master branch if no branch is specified" do            
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cr=\`git ls-remote #{@config_repository} refs/heads/master\`;")))
          end
          
          it "should query the head of the config repository's specified branch if a branch is specified" do
            WhiskeyDisk.configuration = @parameters.merge({'config_branch' => 'production'})
            WhiskeyDisk.enable_staleness_checks
            WhiskeyDisk.enqueue("COMMAND")
            WhiskeyDisk.bundle.should.match(Regexp.new(Regexp.escape("cr=\`git ls-remote #{@config_repository} refs/heads/production\`;")))
          end
        end
      end
    end
  end
  
  describe 'when running a command string remotely' do
    before do
      @domain = 'ogc@ogtastic.com'
      WhiskeyDisk.configuration = { 'domain' => @domain }
      WhiskeyDisk.stub!(:system)      
    end
    
    it 'should accept a command string' do
      lambda { WhiskeyDisk.run('ls') }.should.not.raise(ArgumentError)
    end
    
    it 'should require a command string' do
      lambda { WhiskeyDisk.run }.should.raise(ArgumentError)
    end
    
    it 'should fail if the domain path is not specified' do
      WhiskeyDisk.configuration = {}
      lambda { WhiskeyDisk.run('ls') }.should.raise
    end
    
    it 'should pass the string to ssh with verbosity enabled' do
      WhiskeyDisk.should.receive(:system).with('ssh', '-v', @domain, "set -x; ls")
      WhiskeyDisk.run('ls')
    end
  end
end

