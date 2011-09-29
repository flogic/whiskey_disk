require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a local deployment' do
    before do
      setup_deployment_area
      @config = scenario_config('local/deploy.yml')
    end
    
    describe 'when staleness checkes are enabled' do
      before do
        @args = "--path=#{@config} --to=project:local-default --check"
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'does not update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == false
        end

        it 'reports the local deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /local => succeeded/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  end

  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
      @config = scenario_config('remote/deploy.yml')
    end

    describe 'when staleness checkes are enabled' do
      before do
        @args = "--path=#{@config} --to=project:remote --check"
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'does not update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == false
        end

        it 'reports the local deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  end
end