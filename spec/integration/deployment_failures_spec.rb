require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do  
  describe 'when specified project cannot be found in the configuration' do
    before do
      setup_deployment_area
      
      @config = scenario_config('remote/deploy.yml')
      @args = "--path=#{@config} --to=bogus:remote"
    end

    describe 'and performing a setup' do
      it 'should not checkout a repository for the project to the target path' do
        run_setup(@args)
        File.exists?(deployed_file('bogus')).should == false
      end
      
      it 'should not checkout a repository for any project in the configuration file to the target path' do
        run_setup(@args)
        File.exists?(deployed_file('project')).should == false
      end
      
      it 'should include a helpful error message' do
        run_setup(@args)
        File.read(integration_log).should =~ /No configuration file defined data for project `bogus`/
      end
      
      it 'should exit with a false status' do
        run_setup(@args).should == false
      end
    end

    describe 'and performing a deployment' do
      before do
        checkout_repo('project')
        File.unlink(deployed_file('project/README'))  # modify the deployed checkout
      end        

      it 'should not checkout a repository for the project to the target path' do
        run_deploy(@args)
        File.exists?(deployed_file('bogus')).should == false
      end
      
      it 'should not update the repository for any project in the configuration file to the target path' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == false
      end
      
      it 'should include a helpful error message' do
        run_deploy(@args)
        File.read(integration_log).should =~ /No configuration file defined data for project `bogus`/
      end
      
      it 'should exit with a false status' do
        run_deploy(@args).should == false
      end
    end
  end
  
  describe 'when specified environment cannot be found in the configuration' do
    before do
      setup_deployment_area
      
      @config = scenario_config('remote/deploy.yml')
      @args = "--path=#{@config} --to=project:bogus"
    end

    describe 'and performing a setup' do
      it 'should not checkout a repository for the project to the target path' do
        run_setup(@args)
        File.exists?(deployed_file('project')).should == false
      end
      
      it 'should include a helpful error message' do
        run_setup(@args)
        File.read(integration_log).should =~ /No configuration file defined data for project `project`, environment `bogus`/
      end
      
      it 'should exit with a false status' do
        run_setup(@args).should == false
      end
    end

    describe 'and performing a deployment' do
      before do
        checkout_repo('project')
        File.unlink(deployed_file('project/README'))  # modify the deployed checkout
      end        

      it 'should not update the repository for the project to the target path' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == false
      end
      
      it 'should include a helpful error message' do
        run_deploy(@args)
        File.read(integration_log).should =~ /No configuration file defined data for project `project`, environment `bogus`/
      end
      
      it 'should exit with a false status' do
        run_deploy(@args).should == false
      end
    end
  end
end