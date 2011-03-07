require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
    end
  
    describe 'with a single remote domain' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:remote"
      end

      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
            
        it 'should have the working copy set to the master branch' do
          run_setup(@args)
          current_branch('project').should == 'master'
        end

        it 'should have the working copy set to the specified branch when one is available' do
          @args = "--path=#{@config} --to=project:remote-on-other-branch"
          run_setup(@args)
          current_branch('project').should == 'no_rake_hooks'
        end

        it 'should report the remote setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end
        
        it 'should exit with a true status' do
          run_setup(@args).should == true
        end
      end
    
      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'should update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        it 'should have the working copy set to the master branch' do
          run_deploy(@args)
          current_branch('project').should == 'master'
        end

        it 'should have the working copy set to the specified branch when one is available' do
          @args = "--path=#{@config} --to=project:remote-on-other-branch"
          run_deploy(@args)
          current_branch('project').should == 'no_rake_hooks'          
        end

        it 'should report the remote deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  end
end