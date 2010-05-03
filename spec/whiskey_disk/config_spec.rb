require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))
require 'yaml'

CURRENT = File.expand_path(File.dirname(__FILE__))  # BACON evidently mucks around with __FILE__ or something related :-/

describe WhiskeyDisk::Config do
  describe 'when fetching configuration' do
    before do
      ENV['to'] = @env = 'staging'
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
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'} }))
      lambda { WhiskeyDisk::Config.fetch }.should.raise
    end
    
    it 'should return the configuration yaml file data for this environment as a hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      result = WhiskeyDisk::Config.fetch
      staging.each_pair do |k,v|
        result[k].should == v
      end
    end
    
    it 'should not include configuration information for other environments in the returned hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['a'].should.be.nil
    end
    
    it 'should include the environment in the hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['environment'].should == 'staging'
    end
    
    it 'should not allow overriding the environment in the configuration file' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'environment' => 'production' }
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['environment'].should == 'staging'
    end
    
    it 'should include the project handle in the hash' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
      WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['project'].should == 'whiskey_disk'
    end
    
    it 'should allow overriding the project handle in the configuration file' do
      staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'project' => 'diskey_whisk' }
      WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
      WhiskeyDisk::Config.stub!(:configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
      WhiskeyDisk::Config.fetch['project'].should == 'diskey_whisk'
    end
  end

  describe 'computing the project name from a configuration hash' do
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

  describe 'finding the main configuration file' do
    before do
      ENV['to'] = @env = 'staging'
    end
    
    it 'should return the path to a per-environment configuration file in the config directory under the project base path if it exists' do
      WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project')
      File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(true)
      WhiskeyDisk::Config.configuration_file.should == '/path/to/project/config/deploy/staging.yml'      
    end
    
    it 'should return the path to deploy.yml in the config directory under the project base path' do
      WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project')
      File.stub!(:exists?).with('/path/to/project/config/deploy/staging.yml').and_return(false)
      WhiskeyDisk::Config.configuration_file.should == '/path/to/project/config/deploy.yml'
    end
  end
  
  describe 'computing the base path for the project' do
    it 'should fail if there is no Rakefile along the root path to the current directory'  do
      WhiskeyDisk::Config.stub!(:contains_rakefile?).and_return(false)
      lambda { WhiskeyDisk::Config.base_path }.should.raise
    end
    
    it 'return the nearest enclosing path with a Rakefile along the root path to the current directory' do
      top = ::File.expand_path(File.join(CURRENT, '..', '..'))
      WhiskeyDisk::Config.stub!(:contains_rakefile?).and_return(false)
      WhiskeyDisk::Config.stub!(:contains_rakefile?).with(top).and_return(true)
      Dir.chdir(CURRENT)
      WhiskeyDisk::Config.base_path.should == top
    end
  end
end