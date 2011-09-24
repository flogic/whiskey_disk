require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
    end
  
    describe 'and deploying on a different branch than originally deployed' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:remote"
        run_setup(@args)
        run_deploy(@args)

        @args = "--path=#{@config} --to=project:remote-on-other-branch"
        File.unlink(deployed_file('project/README'))  # modify the deployed checkout
      end
      
      it 'updates the checkout of the repository on the target path' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == true
      end    

      it 'has the working copy set to the new branch' do
        run_deploy(@args)
        current_branch('project').should == 'no_rake_hooks'
      end

      it 'reports the remote deployment as successful' do
        run_deploy(@args)
        File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
      end

      it 'exits with a true status' do
        run_deploy(@args).should == true
      end
    end
  end
end