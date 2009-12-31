require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))
require 'yaml'

CURRENT = File.expand_path(File.dirname(__FILE__))  # BACON evidently mucks around with __FILE__ or something related :-/

describe WhiskeyDisk::Config do
  describe 'when fetching configuration' do
    it 'should fail if the current environment cannot be determined' do
      ENV['to'] = nil
      lambda { WhiskeyDisk::Config.fetch }.should.raise
    end
    
    describe 'when there is no separate configuration file for the current environment' do
      before do
        ENV['to'] = @env = 'staging'
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(nil)
      end
      
      it 'should fail if the main configuration file does not exist' do
        WhiskeyDisk::Config.stub!(:main_configuration_file).and_return(__FILE__ + "_.crap")
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end
      
      it 'should fail if the main configuration file cannot be read' do
        WhiskeyDisk::Config.stub!(:main_configuration_file).and_return("/tmp")
        lambda { WhiskeyDisk::Config.fetch }.should.raise        
      end
      
      it 'should fail if the main configuration file is invalid' do
        YAML.stub!(:load).and_raise
        lambda { WhiskeyDisk::Config.fetch }.should.raise        
      end
      
      it 'should fail if the main configuration file does not define data for this environment' do
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'} }))
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end
      
      it 'should return the main configuration yaml file data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        result = WhiskeyDisk::Config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
      
      it 'should not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        WhiskeyDisk::Config.fetch['a'].should.be.nil
      end
      
      it 'should include the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'
      end
      
      it 'should not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'environment' => 'production' }
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'
      end
      
      it 'should include the project handle in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        WhiskeyDisk::Config.fetch['project'].should == 'whiskey_disk'
      end
      
      it 'should allow overriding the project handle in the configuration file' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'project' => 'diskey_whisk' }
        WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'}, 'staging' => staging }))
        WhiskeyDisk::Config.fetch['project'].should == 'diskey_whisk'
      end
    end

    describe 'when there is a separate configuration file for the current environment' do
      before do
        ENV['to'] = @env = 'staging'
        WhiskeyDisk::Config.stub!(:environment_configuration_file).and_return(__FILE__)
        WhiskeyDisk::Config.stub!(:main_configuration_file).and_return(__FILE__)
      end
      
      it 'should fail if the main configuration file does not exist' do
        WhiskeyDisk::Config.stub!(:main_configuration_file).and_return(__FILE__ + "_.crap")
        lambda { WhiskeyDisk::Config.fetch }.should.raise(RuntimeError)
      end
      
      it 'should fail if the main configuration file cannot be read' do
        WhiskeyDisk::Config.stub!(:main_configuration_file).and_return("/tmp")
        lambda { WhiskeyDisk::Config.fetch }.should.raise(RuntimeError)    
      end
      
      it 'should fail if the main configuration file is invalid' do
        YAML.stub!(:load).and_raise
        lambda { WhiskeyDisk::Config.fetch }.should.raise        
      end
      
      it 'should fail if the separate configuration file cannot be read' do
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({}))
        WhiskeyDisk::Config.stub!(:environment_configuration_file).and_return("/tmp")
        lambda { WhiskeyDisk::Config.fetch }.should.raise        
      end
      
      it 'should fail if the separate configuration file is invalid' do
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({}))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return('BAD DATA')
        YAML.stub!(:load).with('BAD DATA').and_raise
        lambda { WhiskeyDisk::Config.fetch }.should.raise        
      end
      
      it 'should fail if the separate configuration file does not define data for this environment' do
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump({}))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump({ 'production' => { 'a' => 'b'} }))
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end
      
      it 'should return the merger of main and separate yaml configuration data as a hash' do
        main = { 'staging' => { 'foo' => 'bar'}}
        env  = { 'staging' => { 'baz' => 'xyzzy'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        result = WhiskeyDisk::Config.fetch
        main.merge(env)['staging'].each_pair {|k,v| result[k].should == v}
      end
      
      it 'should work even if main does not provide configuration data for this environment' do
        main = { 'production' => { 'foo' => 'bar'}}
        env  = { 'staging' => { 'baz' => 'xyzzy'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        result = WhiskeyDisk::Config.fetch
        env['staging'].each_pair {|k,v| result[k].should == v}
      end
      
      it 'should override main configuration file data with separate configuration file data when there is a conflict' do
        main = { 'production' => { 'foo' => 'bar'}}
        env  = { 'staging' => { 'baz' => 'xyzzy', 'foo' => 'mine'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        result = WhiskeyDisk::Config.fetch
        env['staging'].each_pair {|k,v| result[k].should == v}        
      end
      
      it 'should include the environment in the hash' do
        main = { 'staging' => { 'foo' => 'bar'}}
        env  = { 'staging' => { 'baz' => 'xyzzy'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'
      end
      
      it 'should not allow overriding the environment in the main configuration file' do
        main = { 'staging' => { 'foo' => 'bar', 'environment' => 'production'}}
        env  = { 'staging' => { 'baz' => 'xyzzy'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'        
      end
      
      it 'should not allow overriding the environment in the separate configuration file' do
        main = { 'staging' => { 'foo' => 'bar', 'environment' => 'production'}}
        env  = { 'staging' => { 'baz' => 'xyzzy', 'environment' => 'production'}}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'        
      end
      
      it 'should include the project handle in the hash' do
        main = { 'staging' => { 'foo' => 'bar' }}
        env  = { 'staging' => { 'baz' => 'xyzzy' }}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
        WhiskeyDisk::Config.fetch['project'].should == 'whiskey_disk'
      end
      
      it 'should allow overriding the project handle in the main configuration file' do
        main = { 'staging' => { 'foo' => 'bar', 'project' => 'diskey_whisk' }}
        env  = { 'staging' => { 'baz' => 'xyzzy' }}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
        WhiskeyDisk::Config.fetch['project'].should == 'diskey_whisk'        
      end
      
      it 'should allow overriding the project handle in the separate configuration file' do
        main = { 'staging' => { 'foo' => 'bar', 'project' => 'diskey_whisk' }}
        env  = { 'staging' => { 'baz' => 'xyzzy', 'project' => 'diskey_whisk' }}
        WhiskeyDisk::Config.stub!(:main_configuration_data).and_return(YAML.dump(main))
        WhiskeyDisk::Config.stub!(:environment_configuration_data).and_return(YAML.dump(env))
        WhiskeyDisk::Config.stub!(:project_name).and_return('whiskey_disk')
        WhiskeyDisk::Config.fetch['project'].should == 'diskey_whisk'        
      end
    end    
  end
  
  describe 'when returning the configuration filenames' do    
    before do
      ENV['to'] = @env = 'staging'
      WhiskeyDisk::Config.stub!(:main_configuration_file).and_return('/path/to/main')
      WhiskeyDisk::Config.stub!(:environment_configuration_file).and_return('/path/to/staging')
    end

    it 'should fail if the current environment cannot be determined' do
      ENV['to'] = nil
      lambda { WhiskeyDisk::Config.filenames }.should.raise
    end
    
    it 'should include the location of the main configuration file' do
      WhiskeyDisk::Config.filenames.should.include('/path/to/main')
    end

    it 'should include the location of a separate configuration file for this environment' do
      WhiskeyDisk::Config.filenames.should.include('/path/to/staging')
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
    it 'should return the path to deploy.yml in the config directory under the project base path' do
      WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project')
      WhiskeyDisk::Config.main_configuration_file.should == '/path/to/project/config/deploy.yml'
    end
  end

  describe 'finding the per-environment configuration file' do
    it 'should fail if the current environment cannot be determined' do
      ENV['to'] = nil
      lambda { WhiskeyDisk::Config.environment_configuration_file }.should.raise
    end
    
    it 'should return the path to deploy-<environment>.yml in the config directory under the project base path' do
      ENV['to'] = @env = 'staging'
      WhiskeyDisk::Config.stub!(:base_path).and_return('/path/to/project')
      WhiskeyDisk::Config.environment_configuration_file.should == '/path/to/project/config/deploy-staging.yml'
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