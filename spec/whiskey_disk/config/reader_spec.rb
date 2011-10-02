require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'reader'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'environment'))
require 'yaml'


def write_config_file(data)
  File.open(@config_file, 'w') { |f| f.puts YAML.dump(data) }
end

# class for testing .open calls -- for use with URL config paths
class TestURLReader < WhiskeyDisk::Config::Reader
  def set_response(data)
    @fake_response = YAML.dump(data)
  end

  def open(path)
    @fake_response || raise
  end
end

describe WhiskeyDisk::Config::Reader do
  before do
    @environment = WhiskeyDisk::Config::Environment.new
    @reader = WhiskeyDisk::Config::Reader.new(@environment)
  end

  describe 'when fetching configuration data' do
    describe 'and path specified is an URL' do
      before do
        ENV['to'] = @env = 'foo:staging'
        ENV['path'] = 'https://www.example.com/foo/bar/deploy.yml'
        @reader = TestURLReader.new(@environment)
      end

      it 'fails if the current environment cannot be determined' do
        ENV['to'] = nil
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the configuration data cannot be retrieved' do
        @reader.stub!(:open).and_raise(RuntimeError)
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data is invalid' do
        @reader.stub!(:open).and_return("}")
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the retrieved configuration data does not define data for this environment' do
        @reader.set_response('foo' => { 'production' => { 'a' => 'b'} })
        lambda { @reader.fetch }.should.raise
      end

      it 'returns the retrieved configuration yaml data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        @reader.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @reader.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end

      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'deploy_to' => 'foo', 'repository' => 'x' }
        @reader.set_response('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @reader.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'deploy_to' => 'foo', 'repository' => 'x' }
        @reader.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'environment' => 'production' }
        @reader.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        @reader.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'deploy_to' => 'foo' }
        @reader.set_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        @reader.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['project'].should == 'diskey_whisk'
      end

      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        @reader.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['config_target'].should == 'staging'
      end

      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        @reader.set_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['config_target'].should == 'testing'
      end

      it 'fails if the named target cannot be found' do
        ENV['to'] = @env = 'bogus:thing'
        lambda { @reader.fetch }.should.raise
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
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the configuration file does not exist' do
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the configuration file cannot be read' do
        Dir.mkdir(File.join(@path, 'tmp'))
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the configuration file is invalid' do
        File.open(@config_file, 'w') {|f| f.puts "}" }
        lambda { @reader.fetch }.should.raise
      end

      it 'fails if the configuration file does not define data for this environment' do
        write_config_file('foo' => { 'production' => { 'a' => 'b'} })
        lambda { @reader.fetch }.should.raise
      end

      it 'returns the configuration yaml file data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = @reader.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end

      it 'does not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        @reader.fetch['a'].should.be.nil
      end

      it 'includes the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy', 'repository' => 'x', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['environment'].should == 'staging'
      end

      it 'does not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'environment' => 'production' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['environment'].should == 'staging'
      end

      it 'includes the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['project'].should == 'foo'
      end

      it 'does not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        @reader.fetch['project'].should == 'foo'
      end

      it 'allows overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['project'].should == 'diskey_whisk'
      end

      it 'includes the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['config_target'].should == 'staging'
      end

      it 'includes the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'deploy_to' => 'foo', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        @reader.fetch['config_target'].should == 'testing'
      end

      it 'fails if the named target cannot be found' do
        ENV['to'] = @env = 'bogus:thing'
        lambda { @reader.fetch }.should.raise
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
      lambda { @reader.configuration_data }.should.raise
    end

    it 'returns the contents of the configuration file' do
      File.open(@config_file, 'w') { |f| f.puts "file contents" }
      @reader.configuration_data.should == "file contents\n"
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
      lambda { @reader.load_data }.should.raise
    end

    it 'fails if converting the configuration data from YAML fails' do
      File.open(@config_file, 'w') { |f| f.puts "}" }
      lambda { @reader.load_data }.should.raise
    end

    it 'returns the un-YAMLized configuration data' do
      write_config_file('repository' => 'x')
      @reader.load_data.should == { 'repository' => 'x' }
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
      @reader.filter_data(@data).should == {
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