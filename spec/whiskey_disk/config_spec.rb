require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))
require 'yaml'
require 'tmpdir'
require 'fileutils'

# create a file at the specified path
def make(path)
  FileUtils.mkdir_p(File.dirname(path))
  FileUtils.touch(path)
end

def build_temp_dir
  return Dir.mktmpdir(nil, '/private/tmp') if File.exists?('/private/tmp')
  Dir.mktmpdir
end

def write_config_file(data)
  File.open(@config_file, 'w') { |f| f.puts YAML.dump(data) }
end

# class for testing .open calls -- for use with URL config paths
class TestURLConfig < WhiskeyDisk::Config
  def set_response(data)
    @fake_response = YAML.dump(data)
  end

  def open(path)
    @fake_response || raise
  end
end

describe WhiskeyDisk::Config do
  before do
    @config = WhiskeyDisk::Config.new
  end
  
  describe 'when computing the environment name' do
    it 'returns false when there is no ENV["to"] setting' do
      ENV['to'] = nil
      @config.environment_name.should == false
    end

    it 'returns false when the ENV["to"] setting is blank' do
      ENV['to'] = ''
      @config.environment_name.should == false
    end

    it 'returns the ENV["to"] setting when it is non-blank' do
      ENV['to'] = 'staging'
      @config.environment_name.should == 'staging'
    end

    it 'returns the environment portion of the ENV["to"] setting when a project is specified' do
      ENV['to'] = 'project:staging'
      @config.environment_name.should == 'staging'
    end
  end

  describe 'when determining whether to do a staleness check before updating' do
    it 'returns false when there is no ENV["check"] setting' do
      ENV['check'] = nil
      @config.check_staleness?.should == false
    end

    it 'returns false when the ENV["check"] setting is blank' do
      ENV['check'] = ''
      @config.check_staleness?.should == false
    end

    it 'returns true if the ENV["check"] setting is "t"' do
      ENV['check'] = 't'
      @config.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "true"' do
      ENV['check'] = 'true'
      @config.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "y"' do
      ENV['check'] = 'y'
      @config.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "yes"' do
      ENV['check'] = 'yes'
      @config.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "1"' do
      ENV['check'] = '1'
      @config.check_staleness?.should == true
    end
  end
  
  describe 'when determining whether there is a domain limit set' do
    it 'returns false when ENV["only"] is nil' do
      ENV['only'] = nil
      @config.domain_limit.should == false
    end
    
    it 'returns false when ENV["only"] is empty' do
      ENV['only'] = ''
      @config.domain_limit.should == false
    end
    
    it 'returns the value in ENV["only"] when it is non-empty' do
      ENV['only'] = 'somedomain'
      @config.domain_limit.should == 'somedomain'      
    end
  end

  describe 'when determining whether to turn debug mode on' do
    it 'returns false when there is no ENV["debug"] setting' do
      ENV['debug'] = nil
      @config.debug?.should == false
    end

    it 'returns false when the ENV["debug"] setting is blank' do
      ENV['debug'] = ''
      @config.debug?.should == false
    end

    it 'returns true if the ENV["debug"] setting is "t"' do
      ENV['debug'] = 't'
      @config.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "true"' do
      ENV['debug'] = 'true'
      @config.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "y"' do
      ENV['debug'] = 'y'
      @config.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "yes"' do
      ENV['debug'] = 'yes'
      @config.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "1"' do
      ENV['debug'] = '1'
      @config.debug?.should == true
    end
  end

  describe 'when fetching configuration' do
    describe 'and path specified is an URL' do
      before do
        ENV['to'] = @env = 'foo:staging'
        ENV['path'] = 'https://www.example.com/foo/bar/deploy.yml'
        @config = TestURLConfig.new
      end
      
      it 'fails if the current environment cannot be determined' do
        ENV['to'] = nil
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the configuration data cannot be retrieved' do
        @config.stubs(:open).raises(RuntimeError)
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data is invalid' do
        @config.stubs(:open).returns("}")
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data does not define data for this environment' do
        @config.set_response('foo' => { 'production' => { 'a' => 'b'} })
        lambda { @config.fetch }.should.raise
      end

      it 'returns the retrieved configuration yaml data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        @config.set_response('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @config.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'environment' => 'production' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        @config.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        @config.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'staging'
      end
    
      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        @config.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'testing'
      end
      
      it 'fails if the named target cannot be found' do
        ENV['to'] = @env = 'bogus:thing'
        lambda { @config.fetch }.should.raise
      end
    end
    
    describe 'and path specified is not an URL' do
      before do
        ENV['to'] = @env = 'foo:staging'
        @path = build_temp_dir
        ENV['path'] = @config_file = File.join(@path, 'deploy.yml')
      end

      after do
        FileUtils.rm_rf(@path)
      end
      
      it 'fails if the current environment cannot be determined' do
        ENV['to'] = nil
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the configuration file does not exist' do
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the configuration file cannot be read' do
        Dir.mkdir(File.join(@path, 'tmp'))
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the configuration file is invalid' do
        File.open(@config_file, 'w') {|f| f.puts "}" }
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the configuration file does not define data for this environment' do
        write_config_file('foo' => { 'production' => { 'a' => 'b'} })
        lambda { @config.fetch }.should.raise
      end

      it 'returns the configuration yaml file data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        write_config_file('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @config.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'environment' => 'production' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'staging'
      end
    
      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'testing'
      end
      
      it 'fails if the named target cannot be found' do
        ENV['to'] = @env = 'bogus:thing'
        lambda { @config.fetch }.should.raise
      end
    end
  end

  describe 'returning configuration data from a configuration file' do
    before do
      @path = build_temp_dir
      ENV['path'] = @config_file = File.join(@path, 'deploy.yml')
    end
    
    after do
      FileUtils.rm_rf(@path)
    end

    it 'fails if the configuration file does not exist' do
      lambda { @config.configuration_data }.should.raise
    end

    it 'returns the contents of the configuration file' do
      File.open(@config_file, 'w') { |f| f.puts "file contents" }
      @config.configuration_data.should == "file contents\n"
    end
  end

  describe 'loading data from the configuration file' do
    before do
      ENV['to'] = 'foo:bar'
      @path = build_temp_dir
      ENV['path'] = @config_file = File.join(@path, 'deploy.yml')
    end
    
    after do
      FileUtils.rm_rf(@path)
    end
    
    it 'fails if the configuration data cannot be loaded' do
      lambda { @config.load_data }.should.raise
    end

    it 'fails if converting the configuration data from YAML fails' do
      File.open(@config_file, 'w') { |f| f.puts "}" }
      lambda { @config.load_data }.should.raise
    end

    it 'returns the un-YAMLized configuration data' do
      write_config_file('repository' => 'x')
      @config.load_data.should == { 'repository' => 'x' }
    end    
  end

  describe 'computing the project name' do
    it 'returns the project name from the ENV["to"] setting when it is available' do
      ENV['to'] = 'foo:staging'
      @config.project_name.should == 'foo'
    end

    it 'returns "unnamed_project" when ENV["to"] is unset' do
      ENV['to'] = ''
      @config.project_name.should == 'unnamed_project'
    end

    it 'returns "unnamed_project" when no ENV["to"] project setting is available' do
      ENV['to'] = 'staging'
      @config.project_name.should == 'unnamed_project'
    end
  end

  describe 'finding the configuration file' do
    before do
      ENV['to'] = @env = 'staging'
    end

    describe 'and no path is specified' do
      before do
        ENV['path'] = @path = nil
        @original_path = Dir.pwd
        @base_path = build_temp_dir
        Dir.chdir(@base_path)
        FileUtils.touch(File.join(@base_path, 'Rakefile'))
        @dir = File.join(@base_path, 'config')
        Dir.mkdir(@dir)
        
        [ 
          "/deploy/foo/staging.yml", 
          "/deploy/foo.yml", 
          "/deploy/staging.yml",
          "/staging.yml", 
          "/deploy.yml"
        ].each { |file| make(File.join(@dir, file)) }
      end
      
      after do
        FileUtils.rm_rf(@base_path)
        Dir.chdir(@original_path)
      end
      
      describe 'and a project name is specified in ENV["to"]' do
        before do
          ENV['to'] = @env = 'foo:staging'
        end

        it 'returns the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          @config.configuration_file.should == "#{@dir}/deploy/foo/staging.yml"
        end

        it 'returns the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          @config.configuration_file.should == "#{@dir}/deploy/foo.yml"
        end

        it 'returns the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          @config.configuration_file.should == "#{@dir}/deploy/staging.yml"
        end

        it 'returns the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          @config.configuration_file.should == "#{@dir}/staging.yml"
        end

        it 'returns the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          @config.configuration_file.should == "#{@dir}/deploy.yml"
        end

        it 'fails if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { @config.configuration_file }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'returns the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          @config.configuration_file.should == "#{@dir}/deploy/staging.yml"
        end

        it 'returns the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/staging.yml")
          @config.configuration_file.should == "#{@dir}/staging.yml"
        end

        it 'returns the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          @config.configuration_file.should == "#{@dir}/deploy.yml"
        end

        it 'fails if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { @config.configuration_file }.should.raise
        end
      end
    end

    describe 'and looking up a file' do
      before do
        @path = build_temp_dir
        ENV['path'] = @config_file = File.join(@path, 'deploy.yml')
      end
      
      after do
        FileUtils.rm_rf(@path)
      end
    
      it 'fails if a path is specified which does not exist' do
        lambda { @config.configuration_file }.should.raise
      end

      it 'returns the file path when a path which points to an existing file is specified' do
        FileUtils.touch(@config_file)
        @config.configuration_file.should == @config_file
      end
    end

    describe 'and a path which points to a directory is specified' do
      before do
        ENV['path'] = @path = build_temp_dir
        
        [ 
          "/deploy/foo/staging.yml", 
          "/deploy/foo.yml", 
          "/deploy/staging.yml",
          "/staging.yml", 
          "/deploy.yml"
        ].each { |file| make(File.join(@path, file)) }
      end

      after do
        FileUtils.rm_rf(@path)
      end
      
      describe 'and a project name is specified in ENV["to"]' do
        before do
          ENV['to'] = @env = 'foo:staging'
        end

        it 'returns the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          @config.configuration_file.should == File.join(@path, 'deploy', 'foo' ,'staging.yml')
        end

        it 'returns the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          @config.configuration_file.should == File.join(@path, 'deploy', 'foo.yml')
        end

        it 'returns the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          @config.configuration_file.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'returns the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          @config.configuration_file.should == File.join(@path, 'staging.yml')
        end

        it 'returns the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          @config.configuration_file.should == File.join(@path, 'deploy.yml')
        end

        it 'fails if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { @config.configuration_file }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'returns the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          @config.configuration_file.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'returns the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          @config.configuration_file.should == File.join(@path, 'staging.yml')
        end

        it 'returns the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          @config.configuration_file.should == File.join(@path, 'deploy.yml')
        end

        it 'fails if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { @config.configuration_file }.should.raise
        end
      end
    end
  end

  describe 'filtering configuration data' do
    before do
      ENV['to'] = @env = 'foo:erl'
      @data = {
        'foo' => { 
          'xyz' => { 'repository' => 'x' },
          'eee' => { 'repository' => 'x', 'domain' => '' },
          'abc' => { 'repository' => 'x', 'domain' => 'what@example.com' },
          'baz' => { 'repository' => 'x', 'domain' => [ 'bar@example.com', 'baz@domain.com' ]},
          'bar' => { 'repository' => 'x', 'domain' => [ 'user@example.com', nil, 'foo@domain.com' ]},
          'bat' => { 'repository' => 'x', 'domain' => [ 'user@example.com', 'foo@domain.com', '' ]},
          'hsh' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' } ]},
          'mix' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com' }, 'baz@domain.com' ]},            
          'erl' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => '' },
                                                        { 'name' => 'aok@domain.com', 'roles' => [] } ]},
          'rol' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => [ 'db' ] },            
                                                        { 'name' => 'aok@domain.com', 'roles' => 'app' } ]},            
          'wow' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => [ 'db' ] },   
                                                          '', 'foo@bar.example.com',      
                                                        { 'name' => 'aok@domain.com', 'roles' => 'app' } ]},            
        },
  
        'zyx' => {
          'xyz' => { 'repository' => 'x' },
          'eee' => { 'repository' => 'x', 'domain' => '' },
          'abc' => { 'repository' => 'x', 'domain' => 'what@example.com' },
          'hij' => { 'repository' => 'x', 'domain' => [ 'bar@example.com', 'baz@domain.com' ]},
          'def' => { 'repository' => 'x', 'domain' => [ 'user@example.com', nil, 'foo@domain.com' ]},
          'dex' => { 'repository' => 'x', 'domain' => [ 'user@example.com', 'foo@domain.com', '' ]},
          'hsh' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' } ]},
          'mix' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com' }, 'baz@domain.com' ]},
          'erl' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => '' },
                                                        { 'name' => 'aok@domain.com', 'roles' => [] } ]},
          'rol' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => [ 'db' ] },         
                                                        { 'name' => 'aok@domain.com', 'roles' => 'app' } ]},            
          'wow' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => [ 'db' ] },   
                                                           '', 'foo@bar.example.com',      
                                                        { 'name' => 'aok@domain.com', 'roles' => 'app' } ]},            
        }
      }
    end
    
    it 'should apply all available filters' do
      @config.filter_data(@data).should == {
        "repository" => "x", 
        "project" => "foo", 
        "config_target" => "erl", 
        "environment" => "erl",
        "domain"     => [ 
          { 'name' => "bar@example.com" }, 
          { 'name' => "baz@domain.com" }, 
          { 'name' => "aok@domain.com" }
        ]
      }
    end
  end

  describe 'computing the base path for the project' do
    before do
      @original_path = Dir.pwd
      ENV['path'] = @path = nil
    end

    after do
      Dir.chdir(@original_path)
    end

    describe 'and a "path" environment variable is set' do
      before do
        ENV['path'] = @path = build_temp_dir
        @original_path = Dir.pwd
      end
      
      after do
        FileUtils.rm_rf(@path)
        Dir.chdir(@original_path)
      end

      it 'returns the path set in the "path" environment variable' do
        @config.base_path.should == @path
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        @config.base_path
        Dir.pwd.should == @original_path
      end
    end

    describe 'and there is no Rakefile in the root path to the current directory' do
      before do
        @original_path = Dir.pwd
        @path = build_temp_dir
        Dir.chdir(@path)
      end

      after do
        Dir.chdir(@original_path)
        FileUtils.rm_rf(@path)
      end

      it 'returns the config directory under the current directory if there is no Rakefile along the root path to the current directory' do
        @config.base_path.should == File.join(@path, 'config')
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        @config.base_path
        Dir.pwd.should == prior
      end
    end

    describe 'and there is a Rakefile in the root path to the current directory' do
      before do
        @original_path = Dir.pwd
        @path = build_temp_dir
        Dir.chdir(@path)
        FileUtils.touch(File.join(@path, 'Rakefile'))
      end

      after do
        Dir.chdir(@original_path)
        FileUtils.rm_rf(@path)
      end

      it 'return the config directory in the nearest enclosing path with a Rakefile along the root path to the current directory' do
        @config.base_path.should == File.join(@path, 'config')
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        @config.base_path
        Dir.pwd.should == prior
      end
    end
  end
end
