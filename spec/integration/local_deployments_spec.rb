require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a local deployment' do
    before do
      setup_deployment_area
    end

    describe 'when the configuration specifies no domain' do
      before do
        @config = scenario_config('local/deploy.yml')
        @args = "--path=#{@config} --to=project:local-default"
      end

      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the local setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /local => succeeded/
        end

        it 'exits with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'updates the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
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

    describe 'when the configuration specifies a single domain via the "local" keyword' do
      before do
        @config = scenario_config('local/deploy.yml')
        @args = "--path=#{@config} --to=project:local-keyword"
      end

      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the local setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /local => succeeded/
        end

        it 'exits with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'updates the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
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

    describe 'when the configuration specifies a single domain specified as user@domain, using --only=domain' do
      before do
        @config = scenario_config('local/deploy.yml')
        @args = "--path=#{@config} --to=project:local-user-domain --only=localhost"
      end

      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the named domain setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'updates the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the named domain deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end

    describe 'when the configuration specifies a single domain without username, using --only=domain' do
      before do
        @config = scenario_config('local/deploy.yml')
        @args = "--path=#{@config} --to=project:local-domain --only=localhost"
      end

      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the named domain setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'performing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end

        it 'updates the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end

        it 'reports the named domain deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end

    describe 'when the configuration specifies a single domain which does not match the --only domain' do
      before do
        @config = scenario_config('local/deploy.yml')
        @args = "--path=#{@config} --to=project:local-domain --only=vagrant2"
      end

      describe 'performing a setup' do
        it 'does not perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == false
        end

        it 'reports that there were no deployments' do
          run_setup(@args)
          File.read(integration_log).should =~ /No deployments/
        end

        it 'exits with a true status' do
          run_setup(@args).should == true
        end
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

        it 'reports that there were no deployments' do
          run_deploy(@args)
          File.read(integration_log).should =~ /No deployments/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  end
end