require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require 'rake'

describe 'rake tasks' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'tasks', 'deploy.rb'))
    WhiskeyDisk.reset
  end

  after do
    Rake.application = nil
  end
  
  describe 'deploy:setup' do
    describe 'when a domain is specified' do
      before do
        @configuration = { 'domain' => 'some domain'}
        WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
        [ 
          :ensure_main_parent_path_is_present, 
          :ensure_config_parent_path_is_present,
          :checkout_main_repository,
          :install_hooks,
          :checkout_configuration_repository,
          :refresh_configuration,
          :run_post_setup_hooks
        ].each do |meth| 
          WhiskeyDisk.stub!(meth) 
        end
      end
      
      it 'should make changes on the specified domain' do
        @rake["deploy:setup"].invoke
        WhiskeyDisk.should.be.remote
      end
      
      it 'should ensure that the parent path for the main repository checkout is present' do
        WhiskeyDisk.should.receive(:ensure_main_parent_path_is_present)
        @rake["deploy:setup"].invoke
      end
      
      it 'should ensure that the parent path for the configuration repository checkout is present' do
        WhiskeyDisk.should.receive(:ensure_config_parent_path_is_present)
        @rake["deploy:setup"].invoke        
      end
      
      it 'should check out the main repository' do
        WhiskeyDisk.should.receive(:checkout_main_repository)
        @rake["deploy:setup"].invoke
      end
      
      it 'should install a post-receive hook on the checked out repository' do
        WhiskeyDisk.should.receive(:install_hooks)
        @rake["deploy:setup"].invoke        
      end
      
      it 'should check out the configuration repository' do
        WhiskeyDisk.should.receive(:checkout_configuration_repository)
        @rake["deploy:setup"].invoke
      end
      
      it 'should refresh the configuration' do
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:setup"].invoke
      end
      
      it 'should run any post setup hooks' do        
        WhiskeyDisk.should.receive(:run_post_setup_hooks)
        @rake["deploy:setup"].invoke
      end
    end
    
    describe 'when no domain is specified' do
      before do
        @configuration = { 'domain' => '' }
        WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
        
        [ 
          :ensure_config_parent_path_is_present,
          :checkout_configuration_repository,
          :refresh_configuration,
          :run_post_setup_hooks
        ].each do |meth| 
          WhiskeyDisk.stub!(meth) 
        end
      end
      
      it 'should make changes on the local system' do
        WhiskeyDisk.should.not.be.remote
      end
      
      it 'should NOT ensure that the parent path for the main repository checkout is present' do
        WhiskeyDisk.should.not.receive(:ensure_main_parent_path_is_present)
        @rake["deploy:setup"].invoke
      end
      
      it 'should ensure that the parent path for the configuration repository checkout is present' do
        WhiskeyDisk.should.receive(:ensure_config_parent_path_is_present)
        @rake["deploy:setup"].invoke        
      end
      
      it 'should NOT check out the main repository' do
        WhiskeyDisk.should.not.receive(:checkout_main_repository)
        @rake["deploy:setup"].invoke
      end
      
      it 'should NOT install a post-receive hook on the checked out repository' do
        WhiskeyDisk.should.not.receive(:install_hooks)
        @rake["deploy:setup"].invoke        
      end
      
      it 'should check out the configuration repository' do
        WhiskeyDisk.should.receive(:checkout_configuration_repository)
        @rake["deploy:setup"].invoke
      end
      
      it 'should refresh the configuration' do
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:setup"].invoke
      end
      
      it 'should run any post setup hooks' do        
        WhiskeyDisk.should.receive(:run_post_setup_hooks)
        @rake["deploy:setup"].invoke
      end
    end
  end
  
  describe 'deploy:now' do
    describe 'when a domain is specified' do
      before do
        @configuration = { 'domain' => 'some domain'}
        WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
        [ 
          :update_main_repository_checkout,
          :update_configuration_repository_checkout,
          :refresh_configuration,
          :run_post_deploy_hooks
        ].each do |meth| 
          WhiskeyDisk.stub!(meth) 
        end
      end
      it 'should make changes on the specified domain' do
        @rake["deploy:now"].invoke
        WhiskeyDisk.should.be.remote
      end
      
      it 'should update the main repository checkout' do
        WhiskeyDisk.should.receive(:update_main_repository_checkout)
        @rake["deploy:now"].invoke
      end
      
      it 'should update the configuration repository checkout' do
        WhiskeyDisk.should.receive(:update_configuration_repository_checkout)
        @rake["deploy:now"].invoke
      end
      
      it 'should refresh the configuration' do
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:now"].invoke
      end
      
      it 'should run any post deployment hooks' do        
        WhiskeyDisk.should.receive(:run_post_deploy_hooks)
        @rake["deploy:now"].invoke
      end
    end
    
    describe 'when no domain is specified' do
      before do
        @configuration = { 'domain' => '' }
        WhiskeyDisk::Config.stub!(:fetch).and_return(@configuration)
        
        [ 
          :update_configuration_repository_checkout,
          :refresh_configuration,
          :run_post_deploy_hooks
        ].each do |meth| 
          WhiskeyDisk.stub!(meth) 
        end
      end

      it 'should make changes on the local system' do
        WhiskeyDisk.should.not.be.remote
      end
      
      it 'should NOT update the main repository checkout' do
        WhiskeyDisk.should.not.receive(:update_main_repository_checkout)
        @rake["deploy:now"].invoke
      end
      
      it 'should update the configuration repository checkout' do
        WhiskeyDisk.should.receive(:update_configuration_repository_checkout)
        @rake["deploy:now"].invoke
      end
      
      it 'should refresh the configuration' do
        WhiskeyDisk.should.receive(:refresh_configuration)
        @rake["deploy:now"].invoke
      end
      
      it 'should run any post deployment hooks' do        
        WhiskeyDisk.should.receive(:run_post_deploy_hooks)
        @rake["deploy:now"].invoke
      end    
    end
  end
end
