require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when a post_deploy hook uses the changed? method' do
    before do
      setup_deployment_area
      @config = scenario_config('remote/deploy.yml')
      @args = "--path=#{@config} --to=project:hook_with_changed"
    end
    
    describe 'and performing a setup' do
      it 'should perform a checkout of the repository to the target path' do
        run_setup(@args)
        File.exists?(deployed_file('project/README')).should == true
      end

      it 'should consider all files changed, running any actions guarded by #changed?' do
        run_setup(@args)
        File.read(integration_log).should =~ /changed\? was true/
      end

      it 'should consider all files changed, not running any actions guarded by ! #changed?' do
        run_setup(@args)
        File.read(integration_log).should.not =~ /changed\? was false/
      end

      it 'should report the remote setup as successful' do
        run_setup(@args)
        File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
      end

      it 'should exit with a true status' do
        run_setup(@args).should == true
      end
    end
    
    describe 'and performing a deployment' do
      before do
        checkout_repo('project', 'hook_with_changed')
        jump_to_initial_commit('project') # reset the deployed checkout
      end

      it 'should update the repo checkout' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == true
      end
      
      it 'should run actions contingent on file changes' do
        run_deploy(@args)
        File.read(integration_log).should =~ /changed\? was true/
      end

      it 'should not run actions contingent upon files not changing' do
        run_deploy(@args)
        File.read(integration_log).should =~ /changed\? was false/
      end

      it 'should exit with a true status' do
        run_deploy(@args).should == true
      end      

      it 'should report the deployment as successful' do
        run_deploy(@args)
        File.read(integration_log).should =~ /wd-app1.example.com => succeeded/        
      end
    end
  end
end