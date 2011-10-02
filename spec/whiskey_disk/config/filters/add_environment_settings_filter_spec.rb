require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'add_environment_settings_filter'))

describe 'storing environment values into the configuration hash' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::AddEnvironmentSettingsFilter.new(@config)
    ENV['to'] = 'project:environment'
  end

  describe 'storing environment name' do
    it 'adds an environment value when none is present' do
      @filter.filter('foo' => 'bar')['environment'].should == 'environment'
    end
  
    it 'overwrites an environment value when one is present' do
      @filter.filter('environment' => 'baz', 'foo' => 'bar')['environment'].should == 'environment'
    end
  end
  
  describe 'storing project name' do
    describe 'when there is a project set in the ENVironment' do
      before do
        ENV['to'] = 'project:environment'
      end
      
      it 'adds a project value when none is present' do
        @filter.filter('foo' => 'bar')['project'].should == 'project'
      end
  
      it 'overwrites a project value when one is present' do
        @filter.filter('project' => 'baz', 'foo' => 'bar')['project'].should == 'project'
      end
    end
  
    describe 'when there is no project set in the ENVironment' do
      before do
        ENV['to'] = ''
      end
    
      it 'adds an "unnamed project" value when no project is present' do
        @filter.filter('foo' => 'bar')['project'].should == 'unnamed_project'
      end
  
      it 'overwrites an environment value when one is present' do
        @filter.filter('project' => 'baz', 'foo' => 'bar')['project'].should == 'unnamed_project'
      end
    end
  end
end