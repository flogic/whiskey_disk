require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
    end
  
    describe 'with no post_* scripts defined' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:no_post_scripts"
      end
      
      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'does not run a post_setup script' do
          run_setup(@args)
          File.read(integration_log).should.not =~ /^Running post script/
        end
            
        it 'reports the remote setup as successful' do
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

        it 'does not run a post_deploy script' do
          run_deploy(@args)
          File.read(integration_log).should.not =~ /^Running post script/
        end
            
        it 'reports the remote deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /vagrant => succeeded/
        end

        it 'exits with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
    
    describe 'with missing post_* scripts defined' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:missing_post_scripts"
      end
      
      describe 'performing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'attempts to run a post_setup script' do
          run_setup(@args)
          File.read(integration_log).should =~ /^Running post script/
        end
        
        it 'passes environment variable settings to the post_setup script' do
          run_setup(@args)
          File.read(integration_log).should =~ /FOO=BAR/
        end
            
        it 'reports the remote setup as a failure' do
          run_setup(@args)
          File.read(integration_log).should =~ /vagrant => failed/
        end

        it 'exits with a false status' do
          run_setup(@args).should == false
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

        it 'attempts to run a post_deploy script' do
          run_deploy(@args)
          File.read(integration_log).should =~ /^Running post script/
        end
            
        it 'passes environment variable settings to the post_deploy script' do
          run_deploy(@args)
          File.read(integration_log).should =~ /FOO='BAR'/
        end
            
        it 'reports the remote deployment as a failure' do
          run_deploy(@args)
          File.read(integration_log).should =~ /vagrant => failed/
        end

        it 'exits with a false status' do
          run_deploy(@args).should == false
        end
      end      
    end
    
    describe 'with post_* scripts specified and present' do
      before do
        @config = scenario_config('remote/deploy.yml')
        @args = "--path=#{@config} --to=project:with_post_scripts"
      end
      
      describe 'and doing a setup' do
        it 'performs a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        describe 'and the post_setup script is successful' do
          it 'runs the post_setup script' do
            run_setup(@args)
            File.read(integration_log).should =~ /^Running the post_setup script/
          end

          it 'passes environment variable settings to the post_setup script' do
            run_setup(@args)
            File.read(integration_log).should =~ /FOO=BAR/
          end

          it 'reports the remote setup as successful' do
            run_setup(@args)
            File.read(integration_log).should =~ /vagrant => succeeded/
          end

          it 'exits with a true status' do
            run_setup(@args).should == true
          end          
        end
        
        describe 'and the post_setup script fails' do
          before do
            @args = "--path=#{@config} --to=project:with_failing_post_scripts"
          end
          
          it 'runs the post_setup script' do
            run_setup(@args)
            File.read(integration_log).should =~ /^Running the post_setup script/
          end

          it 'passes environment variable settings to the post_setup script' do
            run_setup(@args)
            File.read(integration_log).should =~ /FOO=BAR/
          end

          it 'reports the remote setup as a failure' do
            run_setup(@args)
            File.read(integration_log).should =~ /vagrant => failed/
          end

          it 'exits with a false status' do
            run_setup(@args).should == false
          end          
        end
      end

      describe 'and doing a deploy' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'updates the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        describe 'and the post_deploy script is successful' do
          it 'runs the post_deploy script' do
            run_deploy(@args)
            File.read(integration_log).should =~ /^Running the post_deploy script/
          end

          it 'passes environment variable settings to the post_deploy script' do
            run_deploy(@args)
            File.read(integration_log).should =~ /FOO='BAR'/
          end

          it 'reports the remote deployment as successful' do
            run_deploy(@args)
            File.read(integration_log).should =~ /vagrant => succeeded/
          end

          it 'exits with a true status' do
            run_deploy(@args).should == true
          end          
        end
        
        describe 'and the post_deploy script fails' do
          before do
            @args = "--path=#{@config} --to=project:with_failing_post_scripts"
          end
          
          it 'runs the post_deploy script' do
            run_deploy(@args)
            File.read(integration_log).should =~ /^Running the post_deploy script/
          end

          it 'passes environment variable settings to the post_deploy script' do
            run_deploy(@args)
            File.read(integration_log).should =~ /FOO='BAR'/
          end

          it 'reports the remote deployment as a failure' do
            run_deploy(@args)
            File.read(integration_log).should =~ /vagrant => failed/
          end

          it 'exits with a false status' do
            run_deploy(@args).should == false
          end          
        end
      end
    end
  end
end