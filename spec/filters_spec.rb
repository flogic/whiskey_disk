require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk', 'config'))

describe 'filtering configuration data' do  
  describe 'by adding environment scoping' do
    before do
      ENV['to'] = @env = 'foo:staging'

      @config = WhiskeyDisk::Config.new
      @filter = WhiskeyDisk::Config::EnvironmentScopeFilter.new(@config)

      @bare_data  = { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] }
      @env_data   = { 'staging' => @bare_data }
      @proj_data  = { 'foo' => @env_data }
    end

    it 'fails if the configuration data is not a hash' do
      lambda { @filter.filter([]) }.should.raise
    end

    it 'returns the original data if it has both project and environment scoping' do
      @filter.filter(@proj_data).should == @proj_data
    end

    it 'returns the original data if it has environment scoping' do
      @filter.filter(@env_data).should == @env_data
    end

    it 'returns the data wrapped in an environment scope if it has no environment scoping' do
      @filter.filter(@bare_data).should == { 'staging' => @bare_data }
    end
  end

  describe 'by adding project scoping' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = @env = 'foo:staging'

      @bare_data  = { 'staging' => { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] } }
      @proj_data  = { 'foo' => @bare_data }
    end

    it 'fails if the configuration data is not a hash' do
      lambda { @config.add_project_scoping([]) }.should.raise
    end

    describe 'when no project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'staging'
      end

      it 'returns the original data if it has both project and environment scoping' do
        @config.add_project_scoping(@proj_data).should == @proj_data
      end

      describe 'when no project name is specified in the bare config hash' do
        it 'returns the original data wrapped in project scope, using a dummy project, if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'unnamed_project' => @bare_data }
        end
      end

      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['staging']['project'] = 'whiskey_disk'
        end

        it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'whiskey_disk' => @bare_data }
        end
      end
    end

    describe 'when a project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'whiskey_disk:staging'
      end
    
      describe 'when a project name is not specified in the bare config hash' do
        it 'returns the original data if it has both project and environment scoping' do
          @config.add_project_scoping(@proj_data).should == @proj_data
        end
    
        it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'whiskey_disk' => @bare_data }
        end
      end
    
      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['staging']['project'] = 'whiskey_disk'
        end
    
        it 'returns the original data if it has both project and environment scoping' do
          @config.add_project_scoping(@proj_data).should == @proj_data
        end
    
        it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'whiskey_disk' => @bare_data }
        end
      end
    end 
  end

  describe 'normalizing domains' do
    before do
      @config = WhiskeyDisk::Config.new
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
  
    it 'sets the domain to "local" when no domain is specified' do
      @config.normalize_domains(@data)['foo']['xyz']['domain'].should == [ { :name => 'local' } ]   
    end
    
    it 'handles nil domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['xyz']['domain'].should == [ { :name => 'local' } ]
    end
  
    it 'returns domain as "local" if a single empty domain was specified' do
      @config.normalize_domains(@data)['foo']['eee']['domain'].should == [ { :name => 'local' } ]
    end
    
    it 'handles single empty specified domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['eee']['domain'].should == [ { :name => 'local' } ]                 
    end
    
    it 'returns domain as a single element list with a name if a single non-empty domain was specified' do
      @config.normalize_domains(@data)['foo']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
    end
    
    it 'handles single specified domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
    end
  
    it 'returns the list of domain name hashes when a list of domains is specified' do
      @config.normalize_domains(@data)['foo']['baz']['domain'].should == [ 
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
      ]
    end
  
    it 'handles lists of domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['hij']['domain'].should == [ 
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
       ]
    end
    
    it 'replaces any nil domains with "local" domains in a domain list' do
      @config.normalize_domains(@data)['foo']['bar']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
       ]
    end
    
    it 'handles localizing nils across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['def']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
       ]
    end
    
    it 'replaces any blank domains with "local" domains in a domain list' do
      @config.normalize_domains(@data)['foo']['bat']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
       ]
    end
    
    it 'handles localizing blanks across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['dex']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
       ]
    end
    
    it 'does not include roles when only nil, blank or empty roles lists are specified' do
      @config.normalize_domains(@data)['foo']['erl']['domain'].should == [
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
       ]        
    end
  
    it 'handles filtering empty roles across all projects and targets ' do
      @config.normalize_domains(@data)['zyx']['erl']['domain'].should == [
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
       ]        
    end
    
    it 'includes and normalizes roles when specified as strings or lists' do
      @config.normalize_domains(@data)['foo']['rol']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
  
    it 'handles normalizing roles across all projects and targets ' do
      @config.normalize_domains(@data)['zyx']['rol']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
    
    it 'respects empty domains among role data' do
      @config.normalize_domains(@data)['foo']['wow']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'local' },
        { :name => 'foo@bar.example.com' },
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]                
    end
    
    it 'handles empty domain filtering among roles across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['wow']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'local' },
        { :name => 'foo@bar.example.com' },
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
    
    it 'raises an exception if a domain appears more than once in a target' do
      @data = {
        'foo' => { 
          'erl' => { 'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil }, 
                                                        { 'name' => 'baz@domain.com', 'roles' => '' },
                                                        { 'name' => 'bar@example.com', 'roles' => [] } ]},
        }
      }
      
      lambda { @config.normalize_domains(@data) }.should.raise
    end
  end

  describe 'by selecting the data for the project and environment' do
    before do
      @config = WhiskeyDisk::Config.new
      @data = { 
        'project' => { 'environment' => { 'a' => 'b' } },
        'other'   => { 'missing' => { 'c' => 'd' } },
      }
    end
    
    it 'fails when the specified project cannot be found' do
      ENV['to'] = @env = 'something:environment'
      lambda { @config.select_project_and_environment(@data) }.should.raise
    end

    it 'fails when the specified environment cannot be found for the specified project' do
      ENV['to'] = @env = 'other:environment'
      lambda { @config.select_project_and_environment(@data) }.should.raise
    end

    it 'returns only the data for the specified project and environment' do
      ENV['to'] = @env = 'project:environment'
      @config.select_project_and_environment(@data).should == @data['project']['environment']
    end
  end

  describe 'by adding the environment name' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = 'project:environment'
    end
    
    it 'adds an environment value when none is present' do
      @config.add_environment_name('foo' => 'bar').should == { 'environment' => 'environment', 'foo' => 'bar' }
    end
    
    it 'overwrites an environment value when one is present' do
      @config.add_environment_name('environment' => 'baz', 'foo' => 'bar').should == { 'environment' => 'environment', 'foo' => 'bar' }      
    end
  end

  describe 'by adding the project name' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = 'project:environment'
    end
    
    it 'adds an environment value when none is present' do
      @config.add_project_name('foo' => 'bar').should == { 'project' => 'project', 'foo' => 'bar' }
    end
    
    it 'overwrites an environment value when one is present' do
      @config.add_project_name('project' => 'baz', 'foo' => 'bar').should == { 'project' => 'project', 'foo' => 'bar' }      
    end  
  end

  describe 'by defaulting the config target' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = 'project:environment'
    end
    
    it 'adds a config_target value set to the environment name when none is present' do
      @config.default_config_target('foo' => 'bar').should == { 'config_target' => 'environment', 'foo' => 'bar' }
    end
    
    it 'preserves the existing config_target when one is present' do
      @config.default_config_target('config_target' => 'baz', 'foo' => 'bar').should == { 'config_target' => 'baz', 'foo' => 'bar' }      
    end    
  end
end
