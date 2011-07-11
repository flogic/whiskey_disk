require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))
require 'yaml'

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

  describe 'when determining the environment name' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      environment_name = 'fake env name'
      @environment.stub!(:environment_name).and_return(environment_name)
      @config.environment_name.should == environment_name
    end
  end
  
  describe 'when determining the project name' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      project_name = 'fake project name'
      @environment.stub!(:project_name).and_return(project_name)
      @config.project_name.should == project_name
    end
  end
  
  describe 'when determining whether there is a domain limit set' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      domain_limit = 'fake domain limit'
      @environment.stub!(:domain_limit).and_return(domain_limit)
      @config.domain_limit.should == domain_limit
    end
  end
  
  describe 'when determining whether debug mode is on' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      debugging = 'fake debug setting'
      @environment.stub!(:debug?).and_return(debugging)
      @config.debug?.should == debugging
    end    
  end

  describe 'when determining whether staleness checking is on' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      checking = 'fake staleness checking'
      @environment.stub!(:check_staleness?).and_return(checking)
      @config.check_staleness?.should == checking
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
        @config.stub!(:open).and_raise(RuntimeError)
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data is invalid' do
        @config.stub!(:open).and_return("}")
        lambda { @config.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data does not define data for this environment' do
        @config.set_response('foo' => { 'production' => { 'a' => 'b'} })
        lambda { @config.fetch }.should.raise
      end

      it 'returns the retrieved configuration yaml data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'deploy_to' => 'foo', 'repository' => 'x' }
        @config.set_response('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @config.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'deploy_to' => 'foo', 'repository' => 'x' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'environment' => 'production' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'deploy_to' => 'foo' }
        @config.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        @config.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        @config.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'staging'
      end
    
      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
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
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @config.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'environment' => 'production' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @config.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @config.fetch['config_target'].should == 'staging'
      end
    
      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
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
          'erl' => { 'repository' => 'x', 'deploy_to' => 'foo',   'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil }, 
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
        'deploy_to' => 'foo',
        'branch' => 'master',
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
end
