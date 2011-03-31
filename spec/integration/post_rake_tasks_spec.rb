require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
    end
  
    describe 'with no Rakefile in the project' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:no_rakefile"
      end
      
      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'should not run a deploy:post_setup rake task' do
          run_setup(@args)
          File.read(integration_log).should.not =~ /Running a post_setup task/
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

        it 'should not run a deploy:post_deploy rake task' do
          run_deploy(@args)
          File.read(integration_log).should.not =~ /Running a post_deploy task/
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
    
    describe 'with an unparseable Rakefile in the project' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:bad_rakefile"
      end
      
      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'should not run a deploy:post_setup rake task' do
          run_setup(@args)
          File.read(integration_log).should.not =~ /Running a post_setup task/
        end
            
        it 'should report the remote setup as a failure' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => failed/
        end

        it 'should exit with a false status' do
          run_setup(@args).should == false
        end
      end
      
      describe 'performing a deployment' do
        before do
          checkout_repo('project', 'bad_rakefile')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'should update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        it 'should not run a deploy:post_deploy rake task' do
          run_deploy(@args)
          File.read(integration_log).should.not =~ /Running a post_deploy task/
        end
            
        it 'should report the remote deployment as a failure' do
          run_deploy(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => failed/
        end

        it 'should exit with a false status' do
          run_deploy(@args).should == false
        end
      end      
    end
    
    describe 'with a valid Rakefile in the project with no post_setup or post_deploy hooks' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:no_rake_hooks"
      end
      
      describe 'and doing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'should not run a deploy:post_setup rake task' do
          run_setup(@args)
          File.read(integration_log).should.not =~ /Running a post_setup task/
        end
            
        it 'should report the remote setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end

        it 'should exit with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'and doing a deploy' do
        before do
          checkout_repo('project', 'no_rake_hooks')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'should update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        it 'should not run a deploy:post_deploy rake task' do
          run_deploy(@args)
          File.read(integration_log).should.not =~ /Running a post_deploy task/
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
    
    describe 'with a valid Rakefile in the project with post_setup and post_deploy hooks' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:with_rake_hooks"
      end
      
      describe 'and doing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'should run a deploy:post_setup rake task' do
          run_setup(@args)
          File.read(integration_log).should =~ /Running a post_setup task/
        end
            
        it 'should report the remote setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end

        it 'should exit with a true status' do
          run_setup(@args).should == true
        end
      end

      describe 'and doing a deploy' do
        before do
          checkout_repo('project', 'post_rake_tasks')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'should update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        it 'should run a deploy:post_deploy rake task' do
          run_deploy(@args)
          File.read(integration_log).should =~ /Running a post_deploy task/
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