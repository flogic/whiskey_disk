require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk'))

integration_spec do
  describe 'when an invalid configuration file is specified' do
    before do
      setup_deployment_area
      @config = scenario_config('invalid/deploy.yml')
      @args = "--path=#{@config} --to=project:invalid"
    end
    
    describe 'performing a setup' do
      it 'exits with a false status' do
        run_setup(@args).should == false
      end
      
      it 'does not create a repo checkout' do
        run_setup(@args)
        File.exists?(deployed_file('project')).should == false
      end
    end
  
    describe 'performing a deployment' do
      before do
        checkout_repo('project')
        File.unlink(deployed_file('project/README'))  # modify the deployed checkout
      end

      it 'exits with a false status' do
        run_deploy(@args).should == false
      end      
    
      it 'does not update a repo checkout' do
        run_deploy(@args)
        File.exists?(deployed_file('project/README')).should == false
      end
    end
  end
end