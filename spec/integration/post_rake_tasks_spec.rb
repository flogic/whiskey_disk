require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when configured for a remote deployment' do
    before do
      setup_deployment_area
    end
  
    describe 'with no Rakefile in the project' do
      describe 'performing a setup' do
        it 'should perform a checkout of the repository to the target path' do
          run_setup(@args)
          File.exists?(deployed_file('project/README')).should == true
        end
        
        it 'should not run a deploy:post_setup rake task' do
          run_setup(@args)
          File.read(integration_log).should =~ /asdfasdfasfasdfasfa/
        end
            
        it 'should report the remote setup as successful' do
          run_setup(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end

        it 'should exit with a true status' do
          run_setup(@args).should == true
        end
      end
      
      describe 'performaing a deployment' do
        before do
          checkout_repo('project')
          File.unlink(deployed_file('project/README'))  # modify the deployed checkout
        end
        
        it 'should update the checkout of the repository on the target path' do
          run_deploy(@args)
          File.exists?(deployed_file('project/README')).should == true
        end    

        it 'should not run a deploy:post_deploy rake task' do
          run_setup(@args)
          File.read(integration_log).should =~ /asdfasdfasfasdfasfa/
        end
            
        it 'should report the remoate deployment as successful' do
          run_deploy(@args)
          File.read(integration_log).should =~ /wd-app1.example.com => succeeded/
        end

        it 'should exit with a true status' do
          run_deploy(@args).should == true
        end
      end
    end
    
    describe 'with an unparseable Rakefile in the project' do
      describe 'performing a setup' do
      end
      
      describe 'performaing a deployment' do
      end      
    end
    
    describe 'with a valid Rakefile in the project' do
      describe 'but no deploy:post_setup rake task defined' do
        
      end
      
      describe 'and a deploy_post_setup rake task defined' do
        
      end
    end    
  end
end