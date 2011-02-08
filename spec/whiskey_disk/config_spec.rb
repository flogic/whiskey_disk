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
  def self.open
    raise
  end
end

def set_config_url_response(data)
  TestURLConfig.stub!(:open).and_return(YAML.dump(data))
end

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

  describe 'when determining whether to do a staleness check before updating' do
    it 'should return false when there is no ENV["check"] setting' do
      ENV['check'] = nil
      WhiskeyDisk::Config.check_staleness?.should == false
    end

    it 'should return false when the ENV["check"] setting is blank' do
      ENV['check'] = ''
      WhiskeyDisk::Config.check_staleness?.should == false
    end

    it 'should return true if the ENV["check"] setting is "t"' do
      ENV['check'] = 't'
      WhiskeyDisk::Config.check_staleness?.should == true
    end

    it 'should return true if the ENV["check"] setting is "true"' do
      ENV['check'] = 'true'
      WhiskeyDisk::Config.check_staleness?.should == true
    end

    it 'should return true if the ENV["check"] setting is "y"' do
      ENV['check'] = 'y'
      WhiskeyDisk::Config.check_staleness?.should == true
    end

    it 'should return true if the ENV["check"] setting is "yes"' do
      ENV['check'] = 'yes'
      WhiskeyDisk::Config.check_staleness?.should == true
    end

    it 'should return true if the ENV["check"] setting is "1"' do
      ENV['check'] = '1'
      WhiskeyDisk::Config.check_staleness?.should == true
    end
  end
  
  describe 'when determining whether there is a domain limit set' do
    it 'should return false when ENV["only"] is nil' do
      ENV['only'] = nil
      WhiskeyDisk::Config.domain_limit.should == false
    end
    
    it 'should return false when ENV["only"] is empty' do
      ENV['only'] = ''
      WhiskeyDisk::Config.domain_limit.should == false
    end
    
    it 'should return the value in ENV["only"] when it is non-empty' do
      ENV['only'] = 'somedomain'
      WhiskeyDisk::Config.domain_limit.should == 'somedomain'      
    end
  end

  describe 'when fetching configuration' do
    describe 'and path specified is an URL' do
      before do
        ENV['to'] = @env = 'foo:staging'
        ENV['path'] = 'https://www.example.com/foo/bar/deploy.yml'
      end
      
      it 'should fail if the current environment cannot be determined' do
        ENV['to'] = nil
        lambda { TestURLConfig.fetch }.should.raise
      end

      it 'should fail if the configuration data cannot be retrieved' do
        TestURLConfig.stub!(:open).and_raise(RuntimeError)
        lambda { TestURLConfig.fetch }.should.raise
      end

      it 'should fail if the retrieved configuration data is invalid' do
        TestURLConfig.stub!(:open).and_return("}")
        lambda { TestURLConfig.fetch }.should.raise
      end

      it 'should fail if the retrieved configuration data does not define data for this environment' do
        set_config_url_response('foo' => { 'production' => { 'a' => 'b'} })
        lambda { TestURLConfig.fetch }.should.raise
      end

      it 'should return the retrieved configuration yaml data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        set_config_url_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = TestURLConfig.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'should not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        set_config_url_response('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        TestURLConfig.fetch['a'].should.be.nil
      end

      it 'should include the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        set_config_url_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        TestURLConfig.fetch['environment'].should == 'staging'
      end

      it 'should not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'environment' => 'production' }
        set_config_url_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        TestURLConfig.fetch['environment'].should == 'staging'
      end

      it 'should include the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        set_config_url_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        TestURLConfig.fetch['project'].should == 'foo'
      end

      it 'should not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        set_config_url_response('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        TestURLConfig.fetch['project'].should == 'foo'
      end

      it 'should allow overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        set_config_url_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        TestURLConfig.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'should include the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        set_config_url_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        TestURLConfig.fetch['config_target'].should == 'staging'
      end
    
      it 'should include the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        set_config_url_response('production' => { 'repository' => 'b'}, 'staging' => staging)
        TestURLConfig.fetch['config_target'].should == 'testing'
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

      it 'should fail if the current environment cannot be determined' do
        ENV['to'] = nil
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end

      it 'should fail if the configuration file does not exist' do
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end

      it 'should fail if the configuration file cannot be read' do
        Dir.mkdir(File.join(@path, 'tmp'))
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end

      it 'should fail if the configuration file is invalid' do
        File.open(@config_file, 'w') {|f| f.puts "}" }
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end

      it 'should fail if the configuration file does not define data for this environment' do
        write_config_file('foo' => { 'production' => { 'a' => 'b'} })
        lambda { WhiskeyDisk::Config.fetch }.should.raise
      end

      it 'should return the configuration yaml file data for this environment as a hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        result = WhiskeyDisk::Config.fetch
        staging.each_pair do |k,v|
          result[k].should == v
        end
      end
    
      it 'should not include configuration information for other environments in the returned hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        write_config_file('production' => { 'repository' => 'c', 'a' => 'b'}, 'staging' => staging)
        WhiskeyDisk::Config.fetch['a'].should.be.nil
      end

      it 'should include the environment in the hash' do
        staging = { 'foo' => 'bar', 'baz' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'
      end

      it 'should not allow overriding the environment in the configuration file' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'environment' => 'production' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        WhiskeyDisk::Config.fetch['environment'].should == 'staging'
      end

      it 'should include the project handle in the hash' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        WhiskeyDisk::Config.fetch['project'].should == 'foo'
      end

      it 'should not allow overriding the project handle in the configuration file when a project root is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('foo' => { 'production' => { 'repository' => 'b'}, 'staging' => staging })
        WhiskeyDisk::Config.fetch['project'].should == 'foo'
      end

      it 'should allow overriding the project handle in the configuration file when a project root is not specified' do
        ENV['to'] = @env = 'staging'
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        WhiskeyDisk::Config.fetch['project'].should == 'diskey_whisk'
      end
    
      it 'should include the environment name as the config_target setting when no config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        WhiskeyDisk::Config.fetch['config_target'].should == 'staging'
      end
    
      it 'should include the config_target setting when a config_target is specified' do
        staging = { 'foo' => 'bar', 'repository' => 'xyzzy', 'project' => 'diskey_whisk', 'config_target' => 'testing' }
        write_config_file('production' => { 'repository' => 'b'}, 'staging' => staging)
        WhiskeyDisk::Config.fetch['config_target'].should == 'testing'
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

    it 'should fail if the configuration file does not exist' do
      lambda { WhiskeyDisk::Config.configuration_data }.should.raise
    end

    it 'should return the contents of the configuration file' do
      File.open(@config_file, 'w') { |f| f.puts "file contents" }
      WhiskeyDisk::Config.configuration_data.should == "file contents\n"
    end
  end

  describe 'transforming data from the configuration file' do
    before do
      ENV['to'] = 'foo:bar'
      @path = build_temp_dir
      ENV['path'] = @config_file = File.join(@path, 'deploy.yml')
    end
    
    after do
      FileUtils.rm_rf(@path)
    end
    
    it 'should fail if the configuration data cannot be loaded' do
      lambda { WhiskeyDisk::Config.load_data }.should.raise
    end

    it 'should fail if converting the configuration data from YAML fails' do
      File.open(@config_file, 'w') { |f| f.puts "}" }
      lambda { WhiskeyDisk::Config.load_data }.should.raise
    end

    it 'should return a normalized version of the un-YAMLized configuration data' do
      write_config_file('repository' => 'x')
      WhiskeyDisk::Config.load_data.should == { 'foo' => { 'bar' => { 'repository' => 'x', 'domain' => [{ :name => 'local' } ] } } }
    end
    
    describe 'normalizing domains' do
      before do
        write_config_file(
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
        )
      end
    
      it 'should set the domain to "local" when no domain is specified' do
        WhiskeyDisk::Config.load_data['foo']['xyz']['domain'].should == [ { :name => 'local' } ]   
      end
      
      it 'should handle nil domains across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['xyz']['domain'].should == [ { :name => 'local' } ]
      end
    
      it 'should return domain as "local" if a single empty domain was specified' do
        WhiskeyDisk::Config.load_data['foo']['eee']['domain'].should == [ { :name => 'local' } ]
      end
      
      it 'should handle single empty specified domains across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['eee']['domain'].should == [ { :name => 'local' } ]                 
      end
      
      it 'should return domain as a single element list with a name if a single non-empty domain was specified' do
        WhiskeyDisk::Config.load_data['foo']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
      end
  
      it 'should handle single specified domains across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
      end
    
      it 'should return the list of domain name hashes when a list of domains is specified' do
        WhiskeyDisk::Config.load_data['foo']['baz']['domain'].should == [ 
          { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
        ]
      end
    
      it 'should handle lists of domains across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['hij']['domain'].should == [ 
          { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
         ]
      end
      
      it 'should replace any nil domains with "local" domains in a domain list' do
        WhiskeyDisk::Config.load_data['foo']['bar']['domain'].should == [
          { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
         ]
      end
  
      it 'should handle localizing nils across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['def']['domain'].should == [
          { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
         ]
      end
      
      it 'should replace any blank domains with "local" domains in a domain list' do
        WhiskeyDisk::Config.load_data['foo']['bat']['domain'].should == [
          { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
         ]
      end
  
      it 'should handle localizing blanks across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['dex']['domain'].should == [
          { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
         ]
      end
      
      it 'should not include roles when only nil, blank or empty roles lists are specified' do
        WhiskeyDisk::Config.load_data['foo']['erl']['domain'].should == [
          { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
         ]        
      end

      it 'should handle filtering empty roles across all projects and targets ' do
        WhiskeyDisk::Config.load_data['zyx']['erl']['domain'].should == [
          { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
         ]        
      end
      
      it 'should include and normalize roles when specified as strings or lists' do
        WhiskeyDisk::Config.load_data['foo']['rol']['domain'].should == [
          { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
          { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
          { :name => 'aok@domain.com',  :roles => [ 'app' ] }
         ]        
      end

      it 'should handle normalizing roles across all projects and targets ' do
        WhiskeyDisk::Config.load_data['zyx']['rol']['domain'].should == [
          { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
          { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
          { :name => 'aok@domain.com',  :roles => [ 'app' ] }
         ]        
      end
      
      it 'should respect empty domains among role data' do
        WhiskeyDisk::Config.load_data['foo']['wow']['domain'].should == [
          { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
          { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
          { :name => 'local' },
          { :name => 'foo@bar.example.com' },
          { :name => 'aok@domain.com',  :roles => [ 'app' ] }
         ]                
      end
      
      it 'should handle empty domain filtering among roles across all projects and targets' do
        WhiskeyDisk::Config.load_data['zyx']['wow']['domain'].should == [
          { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
          { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
          { :name => 'local' },
          { :name => 'foo@bar.example.com' },
          { :name => 'aok@domain.com',  :roles => [ 'app' ] }
         ]        
      end
      
      it 'should raise an exception if a domain appears more than once in a target' do
        write_config_file(
          'foo' => { 
            'erl' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil }, 
                                                          { 'name' => 'baz@domain.com', 'roles' => '' },
                                                          { 'name' => 'bar@example.com', 'roles' => [] } ]},
          }
        )
        
        lambda { WhiskeyDisk::Config.load_data }.should.raise
        
      end
    end
  end

  describe 'normalizing YAML data from the configuration file' do
    before do
      ENV['to'] = @env = 'foo:staging'

      @bare_data  = { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] }
      @env_data   = { 'staging' => @bare_data }
      @proj_data  = { 'foo' => @env_data }
    end

    it 'should fail if the configuration data is not a hash' do
      lambda { WhiskeyDisk::Config.normalize_data([]) }.should.raise
    end

    describe 'when no project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'staging'
      end

      it 'should return the original data if it has both project and environment scoping' do
        WhiskeyDisk::Config.normalize_data(@proj_data).should == @proj_data
      end

      describe 'when no project name is specified in the bare config hash' do
        it 'should return the original data wrapped in project scope, using a dummy project, if it has environment scoping but no project scoping' do
          WhiskeyDisk::Config.normalize_data(@env_data).should == { 'unnamed_project' => @env_data }
        end

        it 'should return the original data wrapped in a project scope, using a dummy project, and an environment scope if it has neither scoping' do
          WhiskeyDisk::Config.normalize_data(@bare_data).should == { 'unnamed_project' => { 'staging' => @bare_data } }
        end
      end

      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['project'] = 'whiskey_disk'
        end

        it 'should return the original data wrapped in project scope if it has environment scoping but no project scoping' do
          WhiskeyDisk::Config.normalize_data(@env_data).should == { 'whiskey_disk' => @env_data }
        end

        it 'should return the original data wrapped in a project scope and an environment scope if it has neither scoping' do
          WhiskeyDisk::Config.normalize_data(@bare_data).should == { 'whiskey_disk' => { 'staging' => @bare_data } }
        end
      end
    end

    describe 'when a project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'whiskey_disk:staging'
      end

      describe 'when a project name is not specified in the bare config hash' do
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

      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['project'] = 'whiskey_disk'
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
  end

  describe 'computing the project name from a configuration hash' do
    it 'should return the project name from the ENV["to"] setting when it is available' do
      ENV['to'] = 'foo:staging'
      WhiskeyDisk::Config.project_name.should == 'foo'
    end

    it 'should return "unnamed_project" when ENV["to"] is unset' do
      ENV['to'] = ''
      WhiskeyDisk::Config.project_name.should == 'unnamed_project'
    end

    it 'should return "unnamed_project" when no ENV["to"] project setting is available' do
      ENV['to'] = 'staging'
      WhiskeyDisk::Config.project_name.should == 'unnamed_project'
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

        it 'should return the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy/foo/staging.yml"
        end

        it 'should return the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy/foo.yml"
        end

        it 'should return the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy/staging.yml"
        end

        it 'should return the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/staging.yml"
        end

        it 'should return the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy.yml"
        end

        it 'should fail if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { WhiskeyDisk::Config.configuration_file }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'should return the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy/staging.yml"
        end

        it 'should return the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/staging.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/staging.yml"
        end

        it 'should return the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          WhiskeyDisk::Config.configuration_file.should == "#{@dir}/deploy.yml"
        end

        it 'should fail if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { WhiskeyDisk::Config.configuration_file }.should.raise
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
    
      it 'should fail if a path is specified which does not exist' do
        lambda { WhiskeyDisk::Config.configuration_file }.should.raise
      end

      it 'should return the file path when a path which points to an existing file is specified' do
        FileUtils.touch(@config_file)
        WhiskeyDisk::Config.configuration_file.should == @config_file
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

        it 'should return the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy', 'foo' ,'staging.yml')
        end

        it 'should return the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy', 'foo.yml')
        end

        it 'should return the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'should return the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'staging.yml')
        end

        it 'should return the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy.yml')
        end

        it 'should fail if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { WhiskeyDisk::Config.configuration_file }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'should return the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'should return the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'staging.yml')
        end

        it 'should return the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          WhiskeyDisk::Config.configuration_file.should == File.join(@path, 'deploy.yml')
        end

        it 'should fail if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { WhiskeyDisk::Config.configuration_file }.should.raise
        end
      end
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

      it 'should return the path set in the "path" environment variable' do
        WhiskeyDisk::Config.base_path.should == @path
      end

      it 'should leave the current working path the same as when the base path lookup started' do
        WhiskeyDisk::Config.base_path
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

      it 'should return the config directory under the current directory if there is no Rakefile along the root path to the current directory' do
        WhiskeyDisk::Config.base_path.should == File.join(@path, 'config')
      end

      it 'should leave the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        WhiskeyDisk::Config.base_path
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
        WhiskeyDisk::Config.base_path.should == File.join(@path, 'config')
      end

      it 'should leave the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        WhiskeyDisk::Config.base_path
        Dir.pwd.should == prior
      end
    end
  end
end
