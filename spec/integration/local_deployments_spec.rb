require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when an invalid configuration file is specified' do
    before do
      setup_deployment_area
      @config = scenario_config('local-invalid/deploy.yml')
      @args = "--path=#{@config} --to=project:production"
    end
    
    describe 'performing a local setup' do
      it 'should exit with a false status' do
        run_setup(@args).should == false
      end
      
      it 'should not create a repo checkout' do
        run_setup(@args)
        File.exists?(deployed_file('project')).should == false
      end
    end
  
    describe 'performing a local deployment' do
      before do
        checkout_repo('project')
        File.unlink(deployed_file('project/README'))  # modify the deployed checkout
      end

      it 'should exit with a false status' do
        run_deploy(@args).should == false
      end      
    
      it 'should not update a repo checkout' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == false
      end
    end
  end
  
  describe 'when a valid configuration is specified' do
    before do
      setup_deployment_area
    end
    
    describe 'without a domain' do
      before do
        @config = scenario_config('local-valid/deploy.yml')
        @args = "--path=#{@config} --to=project:local-default"
      end

      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
            
        it 'should report the local setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /local => succeeded/
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

        it 'should report the local deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /local => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  
    describe 'with a single domain specified via the local keyword' do
      before do
        @config = scenario_config('local-valid/deploy.yml')
        @args = "--path=#{@config} --to=project:local-keyword"
      end

      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
            
        it 'should report the local setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /local => succeeded/
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

        it 'should report the local deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /local => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
    
    describe 'with a single domain specified as user@domain, using --only=domain' do
      before do
        @config = scenario_config('local-valid/deploy.yml')
        @args = "--path=#{@config} --to=project:local-user-domain --only=wd-app1.example.com"
      end

      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
            
        it 'should report the named domain setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1\.example\.com => succeeded/
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

        it 'should report the named domain deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /wd-app1\.example\.com => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end

    describe 'with a single domain specified without username, using --only=domain' do
      before do
        @config = scenario_config('local-valid/deploy.yml')
        @args = "--path=#{@config} --to=project:local-domain --only=wd-app1.example.com"
      end

      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
            
        it 'should report the named domain setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1\.example\.com => succeeded/
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

        it 'should report the named domain deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /wd-app1\.example\.com => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
  end
end