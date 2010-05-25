require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))
require 'yaml'

CURRENT_FILE = File.expand_path(__FILE__)           # Bacon evidently mucks around with __FILE__ or something related :-/
CURRENT = File.expand_path(File.dirname(__FILE__))  # Bacon evidently mucks around with __FILE__ or something related :-/

describe WhiskeyDisk::Config do
  describe 'when computing the environment name' do
    it 'should return false when there is no ENV["to"] setting' do
      ENV['to'] = nil
      WhiskeyDisk::Config.environment_name.should == false
    end
    
    it 'should return false when the ENV["to"] setting is blank' do
      ENV['to'] = ''
      WhiskeyDisk::Config.environment_name.should == false  
    end
    
    it 'should return the ENV["to"] setting when it is non-blank' do
      ENV['to'] = 'staging'
      WhiskeyDisk::Config.environment_name.should == 'staging'
    end
    
    it 'should return the environment portion of the ENV["to"] setting when a project is specified' do
      ENV['to'] = 'project:staging'
      WhiskeyDisk::Config.environment_name.should == 'staging'      
    end
  end
  
  describe 'when fetching configuration' do
    before do
      ENV['to'] = @env = 'foo:staging'
    end
    
    it 'should fail if the current environment cannot be determined' do
      ENV['to'] = nil
      lambda { WhiskeyDisk::Config.fetch }.should.raise
    end
    
    it 'should fail if the configuration file does not exist' do
      WhiskeyDisk::Config.stub!(:configuration_file).and_return(__FILE__ + "_.crap")
      lambda { WhiskeyDisk::Config.fetch }.should.raise
    end
    
    it 'should fail if the configuration file cannot be read' do
      WhiskeyDisk::Config.stub!(:configuration_file).and_return("/tmp")
      lambda { WhiskeyDisk::Config.fetch }.should.raise        
    end
    
    it 'should fail if the configuration file is invalid' do
      YAML.stub!(:load).and_raise
      lambda { WhiskeyDisk::Config.fetch }.should.raise        
    end
    
    it 'should fail if the configuration file does not define data for this environment' do
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'a' => 'b'}}}))
      lambda { WhiskeyDisk::Config.fetch }.should.raise
    end
    
    it 'should return the configuration yaml file data for this environment as a hash' do
      staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging }}))
      result = WhiskeyDisk::Config.fetch
      staging.each_pair do |k,v|
        result[k].should == v
      end
    end
    
    it 'should not include configuration information for other environments in the returned hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['a'].should.be.nil
    end
    
    it 'should include the environment in the hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging }}))
      WhiskeyDisk::Config.fetch['environment'].should == 'staging'
    end
    
    it 'should not allow overriding the environment in the configuration file' do
      staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'environment' => 'production' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging }}))
      WhiskeyDisk::Config.fetch['environment'].should == 'staging'
    end
    
    it 'should include the project handle in the hash' do
      staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging }}))
      WhiskeyDisk::Config.fetch['project'].should == 'foo'
    end
    
    it 'should not allow overriding the project handle in the configuration file' do
      staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({'foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging }}))
      WhiskeyDisk::Config.fetch['project'].should == 'foo'
    end
  end
  
  describe 'returning configuration data from a configuration file' do
    it 'should fail if the configuration file does not exist' do
      WhiskeyDisk::Config.stub!(:configuration_file).and_return(CURRENT_FILE + '._crap')
      lambda { WhiskeyDisk::Config.configuration_data }.should.raise
    end
    
    it 'should return the contents of the configuration file' do
      WhiskeyDisk::Config.stub!(:configuration_file).and_return(CURRENT_FILE)
      File.stub!(:read).with(CURRENT_FILE).and_return('file contents')
      WhiskeyDisk::Config.configuration_data.should == 'file contents'
    end
  end
  
  describe 'transforming data from the configuration file' do
    it 'should fail if the configuration data cannot be loaded' do
      WhiskeyDisk::Config.stub!(:configuration_data).and_raise
      lambda { WhiskeyDisk::Config.load_data }.should.raise
    end
    
    it 'should fail if converting the configuration data from YAML fails' do
      WhiskeyDisk::Config.stub!(:configuration_data).and_return('configuration data')
      YAML.stub!(:load).and_raise
      lambda { WhiskeyDisk::Config.load_data }.should.raise
    end
    
    it 'should return a normalized version of the un-YAMLized configuration data' do
      data = { 'a' => 'b', 'c' => 'd' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump(data))
      WhiskeyDisk::Config.stub!(:normalize_data).with(data).and_return('normalized data')
      WhiskeyDisk::Config.load_data.should == 'normalized data'
    end
  end
  
  describe 'normalizing YAML data from the configuration file' do
    before do
      ENV['to'] = @env = 'staging'
      
      @bare_data  = { 'repository' => 'git://foo/bar.git', 'domain' => 'ogc@ogtastic.com' }
      @env_data   = { 'staging' => @bare_data }
      @proj_data  = { 'whiskey_disk' => @env_data }
    end
    
    it 'should fail if the configuration data is not a hash' do
      lambda { WhiskeyDisk::Config.normalize_data([]) }.should.raise
    end

    describe 'when no project name is specified via ENV["to"]' do    
      it 'should return the original data if it has both project and environment scoping' do
        WhiskeyDisk::Config.normalize_data(@proj_data).should == @proj_data
      end
        
      it 'should return the original data wrapped in project scope, using the repo project, if it has environment scoping but no project scoping' do
        WhiskeyDisk::Config.normalize_data(@env_data).should == { 'bar' => @env_data }
      end
    
      it 'should return the original data wrapped in a project scope, using the repo project, and an environment scope if it has neither scoping' do
        WhiskeyDisk::Config.normalize_data(@bare_data).should == { 'bar' => { 'staging' => @bare_data } } 
      end
    end

    describe 'when a project name is specified via ENV["to"]' do    
      before do
        ENV['to'] = @env = 'whiskey_disk:staging'
      end
      
      it 'should return the original data if it has both project and environment scoping' do
        WhiskeyDisk::Config.normalize_data(@proj_data).should == @proj_data
      end
        
      it 'should return the original data wrapped in project scope if it has environment scoping but no project scoping' do
        WhiskeyDisk::Config.normalize_data(@env_data).should == { 'whiskey_disk' => @env_data }
      end
    
      it 'should return the original data wrapped in a project scope and an environment scope if it has neither scoping' do
        WhiskeyDisk::Config.normalize_data(@bare_data).should == { 'whiskey_disk' => { 'staging' => @bare_data } } 
      end
    end
  end

  describe 'computing the project name from a configuration hash' do
    it 'should return the project name from the ENV["to"] setting when it is available' do
      ENV['to'] = 'project:staging'
      WhiskeyDisk::Config.project_name({}).should == 'project'      
    end
    
    describe 'when ENV["to"] is unset' do
      before do
        ENV['to'] = ''
      end
      
      it 'should return the empty string if no repository is defined' do
        WhiskeyDisk::Config.project_name({}).should == ''
      end
    
      it 'should return the empty string if the repository is blank' do
        WhiskeyDisk::Config.project_name({ 'repository' => ''}).should == ''
      end
    
      it 'should return the last path segment if the repository does not end in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar/baz'}).should == 'baz'
      end
    
      it 'should return the last path segment, stripping .git, if the repository ends in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar/baz.git'}).should == 'baz'
      end

      it 'should return the last :-delimited segment if the repository does not end in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar:baz'}).should == 'baz'
      end
    
      it 'should return the last :-delimited segment, stripping .git, if the repository ends in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar:baz.git'}).should == 'baz'
      end
    end
    
    describe 'when no ENV["to"] project setting is available' do
      before do
        ENV['to'] = 'staging'
      end
      
      it 'should return the empty string if no repository is defined' do
        WhiskeyDisk::Config.project_name({}).should == ''
      end
    
      it 'should return the empty string if the repository is blank' do
        WhiskeyDisk::Config.project_name({ 'repository' => ''}).should == ''
      end
    
      it 'should return the last path segment if the repository does not end in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar/baz'}).should == 'baz'
      end
    
      it 'should return the last path segment, stripping .git, if the repository ends in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar/baz.git'}).should == 'baz'
      end

      it 'should return the last :-delimited segment if the repository does not end in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar:baz'}).should == 'baz'
      end
    
      it 'should return the last :-delimited segment, stripping .git, if the repository ends in .git' do
        WhiskeyDisk::Config.project_name({ 'repository' => 'git@foo/bar:baz.git'}).should == 'baz'
      end
    end
  end

  describe 'finding the configuration file' do
    before do
      ENV['to'] = @env = 'staging'
    end
    
    describe 'and no path is specified' do    
      before do
        ENV['path'] = @path = nil
      end
          
      it 'should return the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
        WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project/config')
        File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(true)
        WhiskeyDisk::Config.configuration_file.should == '/path/to/project/config/deploy/staging.yml'      
      end
    
      it 'should return the path to a per-environment configuration file under the project base path if it exists' do
        WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project/config')
        File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(false)
        File.stub!(:exists?).with('/path/to/project/config/staging.yml').and_return(true)
        WhiskeyDisk::Config.configuration_file.should == '/path/to/project/config/staging.yml'      
      end
    
      it 'should return the path to deploy.yml under the project base path' do
        WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project/config')
        File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(false)
        File.stub!(:exists?).with('/path/to/project/config/staging.yml').and_return(false)
        File.stub!(:exists?).with('/path/to/project/config/deploy.yml').and_return(true)
        WhiskeyDisk::Config.configuration_file.should == '/path/to/project/config/deploy.yml'
      end

      it 'should fail if no per-environment config file nor deploy.yml exists under the project base path' do
        WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project/config')
        File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(false)
        File.stub!(:exists?).with('/path/to/project/config/staging.yml').and_return(false)
        File.stub!(:exists?).with('/path/to/project/config/deploy.yml').and_return(false)
        lambda { WhiskeyDisk::Config.configuration_file }.should.raise
      end
    end

    it 'should fail if a path is specified which does not exist' do
      ENV['path'] = @path = (CURRENT_FILE + "_.crap")
      lambda { WhiskeyDisk::Config.configuration_file }.should.raise
    end

    it 'should return the file path when a path which points to an existing file is specified' do
      ENV['path'] = @path = CURRENT_FILE
      File.stub!(:exists?).with(@path).and_return(true)
      WhiskeyDisk::Config.configuration_file.should == @path
    end
  
    describe 'and a path which points to a directory is specified' do
      before do
        ENV['path'] = @path = CURRENT
      end
      
      it 'should return the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
        File.stub!(:exists?).with(File.join(@path, 'deploy', 'staging.yml')).and_return(true)
        WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy', 'staging.yml')
      end
      
      it 'should return the path to a per-environment configuration file in the path specified if that file exists' do
        File.stub!(:exists?).with(File.join(@path, 'deploy', 'staging.yml')).and_return(false)
        File.stub!(:exists?).with(File.join(@path, 'staging.yml')).and_return(true)
        WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'staging.yml')
      end
      
      it 'should return the path to deploy.yaml in the path specified if deploy.yml exists' do
        File.stub!(:exists?).with(File.join(@path, 'deploy', 'staging.yml')).and_return(false)
        File.stub!(:exists?).with(File.join(@path, 'staging.yml')).and_return(false)
        File.stub!(:exists?).with(File.join(@path, 'deploy.yml')).and_return(true)
        WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy.yml')
      end
      
      it 'should fail if no per-environment configuration file nor deploy.yml exists in the path specified' do
        File.stub!(:exists?).with(File.join(@path, 'deploy', 'staging.yml')).and_return(false)
        File.stub!(:exists?).with(File.join(@path, 'staging.yml')).and_return(false)
        File.stub!(:exists?).with(File.join(@path, 'deploy.yml')).and_return(false)
        lambda { WhiskeyDisk::Config.configuration_file }.should.raise
      end
    end
  end
  
  describe 'computing the base path for the project' do
    before do
      ENV['path'] = @path = nil
    end
    
    it 'should return the path set in the "path" environment variable when one is set' do
      ENV['path'] = @path = CURRENT
      WhiskeyDisk::Config.base_path.should == @path      
    end
    
    it 'should fail if there is no Rakefile along the root path to the current directory'  do
      WhiskeyDisk::Config.stub!(:contains_rakefile?).and_return(false)
      lambda { WhiskeyDisk::Config.base_path }.should.raise
    end
    
    it 'return the config directory in the nearest enclosing path with a Rakefile along the root path to the current directory' do
      top = ::File.expand_path(File.join(CURRENT, '..', '..'))
      WhiskeyDisk::Config.stub!(:contains_rakefile?).and_return(false)
      WhiskeyDisk::Config.stub!(:contains_rakefile?).with(top).and_return(true)
      Dir.chdir(CURRENT)
      WhiskeyDisk::Config.base_path.should == File.join(top, 'config')
    end
  end
end