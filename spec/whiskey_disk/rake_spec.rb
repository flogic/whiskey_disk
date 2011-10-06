require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require 'rake'

describe 'rake tasks' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'rake.rb'))
    @whiskey_disk = WhiskeyDisk.new
    WhiskeyDisk.stubs(:new).returns(@whiskey_disk)
  end

  after do
    Rake.application = nil
  end
  
  describe 'deploy:setup' do
    before do
      @whiskey_disk.configuration = {}
      [ 
        :ensure_main_parent_path_is_present, 
        :ensure_config_parent_path_is_present,
        :checkout_main_repository,
        :install_hooks,
        :checkout_configuration_repository,
        :update_main_repository_checkout,
        :update_configuration_repository_checkout,
        :refresh_configuration,
        :initialize_all_changes,
        :run_post_setup_hooks, 
        :flush,
        :summarize
      ].each do |meth| 
        @whiskey_disk.stubs(meth)
      end

      @whiskey_disk.stubs(:success?).returns(true)
    end
    
    it 'ensures that the parent path for the main repository checkout is present' do
      @whiskey_disk.expects(:ensure_main_parent_path_is_present)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repo is specified' do
      it 'ensures that the parent path for the configuration repository checkout is present' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:ensure_config_parent_path_is_present)
        @rake["deploy:setup"].invoke    
      end
    end
    
    describe 'when no configuration repo is specified' do
      it 'does not ensure that the path for the configuration repository checkout is present' do
        @whiskey_disk.expects(:ensure_config_parent_path_is_present).never
        @rake["deploy:setup"].invoke        
      end
    end
    
    it 'checks out the main repository' do
      @whiskey_disk.expects(:checkout_main_repository)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'checks out the configuration repository' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:checkout_configuration_repository)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'does not check out the configuration repository' do
        @whiskey_disk.expects(:checkout_configuration_repository).never
        @rake["deploy:setup"].invoke
      end
    end
    
    it 'updates the main repository checkout' do
      @whiskey_disk.expects(:update_main_repository_checkout)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'updates the configuration repository checkout' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:update_configuration_repository_checkout)
        @rake["deploy:setup"].invoke
      end
    end
    
    it 'clears any tracked git or rsync changes' do
      @whiskey_disk.expects(:initialize_all_changes)
      @rake["deploy:setup"].invoke
    end
    
    describe 'when no configuration repository is specified' do
      it 'updates the configuration repository checkout' do
        @whiskey_disk.expects(:update_configuration_repository_checkout).never
        @rake["deploy:setup"].invoke
      end
    end

    describe 'when a configuration repository is specified' do      
      it 'refreshes the configuration' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:refresh_configuration)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do      
      it 'does not refresh the configuration' do
        @whiskey_disk.expects(:refresh_configuration).never
        @rake["deploy:setup"].invoke
      end
    end
    
    it 'runs any post setup hooks' do        
      @whiskey_disk.expects(:run_post_setup_hooks)
      @rake["deploy:setup"].invoke
    end
    
    it 'flushes @whiskey_disk changes' do
      @whiskey_disk.expects(:flush)
      @rake["deploy:setup"].invoke
    end
    
    it 'summarizes the results of the setup run' do
      @whiskey_disk.expects(:summarize)
      @rake["deploy:setup"].invoke
    end
  
    it 'does not exit in error if all setup runs were successful' do
      lambda { @rake["deploy:setup"].invoke }.should.not.raise(SystemExit)
    end
    
    it 'exits in error if some setup run was unsuccessful' do
      @whiskey_disk.stubs(:success?).returns(false)
      lambda { @rake["deploy:setup"].invoke }.should.raise(SystemExit)
    end
  end
  
  describe 'deploy:now' do
    before do
      @whiskey_disk.configuration = { }
      [ 
        :update_main_repository_checkout,
        :update_configuration_repository_checkout,
        :refresh_configuration,
        :run_post_deploy_hooks,
        :flush, 
        :summarize
      ].each do |meth| 
        @whiskey_disk.stubs(meth) 
      end
      
      @whiskey_disk.stubs(:success?).returns(true)
    end
    
    it 'enables staleness checks' do
      WhiskeyDisk.expects(:new).with(:staleness_checks => true).returns(@whiskey_disk)      
      @rake["deploy:now"].invoke
    end
    
    it 'updates the main repository checkout' do
      @whiskey_disk.expects(:update_main_repository_checkout)
      @rake["deploy:now"].invoke
    end
    
    describe 'when a configuration repository is specified' do
      it 'updates the configuration repository checkout' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:update_configuration_repository_checkout)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'does not update the configuration repository checkout' do
        @whiskey_disk.expects(:update_configuration_repository_checkout).never
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when a configuration repository is specified' do
      it 'refreshes the configuration' do
        @whiskey_disk.configuration = { 'config_repository' => 'foo' }
        @whiskey_disk.expects(:refresh_configuration)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when no configuration repository is specified' do
      it 'does not refresh the configuration' do
        @whiskey_disk.expects(:refresh_configuration).never
        @rake["deploy:now"].invoke
      end
    end
    
    it 'runs any post deployment hooks' do        
      @whiskey_disk.expects(:run_post_deploy_hooks)
      @rake["deploy:now"].invoke
    end
    
    it 'flushes @whiskey_disk changes' do
      @whiskey_disk.expects(:flush)
      @rake["deploy:now"].invoke
    end
    
    it 'summarizes the results of the deployment run' do
      @whiskey_disk.expects(:summarize)
      @rake["deploy:now"].invoke
    end
    
    it 'does not exit in error if all deployment runs were successful' do
      lambda { @rake["deploy:now"].invoke }.should.not.raise(SystemExit)
    end
    
    it 'exits in error if some deployment run was unsuccessful' do
      @whiskey_disk.stubs(:success?).returns(false)
      lambda { @rake["deploy:now"].invoke }.should.raise(SystemExit)
    end
  end
      
  describe 'deploy:post_setup' do
    it 'runs the defined post_setup rake task when a post_setup rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'production'}

      task "deploy:production:post_setup" do
        @whiskey_disk.fake_method
      end

      @whiskey_disk.expects(:fake_method)
      Rake::Task['deploy:post_setup'].invoke
    end

    it 'does not fail when no post_setup rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'staging'}
      lambda { Rake::Task['deploy:post_setup'].invoke }.should.not.raise
    end
  end
  
  describe 'deploy:post_deploy' do
    it 'runs the defined post_deploy rake task when a post_deploy rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'production'}

      task "deploy:production:post_deploy" do
        @whiskey_disk.fake_method
      end

      @whiskey_disk.expects(:fake_method)
      Rake::Task['deploy:post_deploy'].invoke
    end

    it 'does not fail when no post_deploy rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'staging'}
      lambda { Rake::Task['deploy:post_deploy'].invoke }.should.not.raise
    end
  end
end
