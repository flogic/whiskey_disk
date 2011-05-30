require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk', 'config'))

# # called only by #fetch
# def filter_data(data)
#   current = add_environment_scoping(data.clone)
#   current = add_project_scoping(current)
#   current = normalize_domains(current)
#   current = check_for_project_and_environment(current)
#   current = add_environment_name(current)
#   current = add_project_name(current)
#   current = default_config_target(current)
# end

describe 'filtering configuration data' do
  
  describe 'by adding environment scoping' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = @env = 'foo:staging'

      @bare_data  = { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] }
      @env_data   = { 'staging' => @bare_data }
      @proj_data  = { 'foo' => @env_data }
    end

    it 'should fail if the configuration data is not a hash' do
      lambda { @config.add_environment_scoping([]) }.should.raise
    end

    it 'should return the original data if it has both project and environment scoping' do
      @config.add_environment_scoping(@proj_data).should == @proj_data
    end

    it 'should return the original data if it has environment scoping' do
      @config.add_environment_scoping(@env_data).should == @env_data
    end

    it 'should return the data wrapped in an environment scope if it has no environment scoping' do
      @config.add_environment_scoping(@bare_data).should == { 'staging' => @bare_data }
    end
  end

  describe 'by adding project scoping' do
    before do
      @config = WhiskeyDisk::Config.new
      ENV['to'] = @env = 'foo:staging'

      @bare_data  = { 'staging' => { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] } }
      @proj_data  = { 'foo' => @bare_data }
    end

    it 'should fail if the configuration data is not a hash' do
      lambda { @config.add_project_scoping([]) }.should.raise
    end

    describe 'when no project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'staging'
      end

      it 'should return the original data if it has both project and environment scoping' do
        @config.add_project_scoping(@proj_data).should == @proj_data
      end

      describe 'when no project name is specified in the bare config hash' do
        it 'should return the original data wrapped in project scope, using a dummy project, if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'unnamed_project' => @bare_data }
        end
      end

      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['staging']['project'] = 'whiskey_disk'
        end

        it 'should return the original data wrapped in project scope if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'whiskey_disk' => @bare_data }
        end
      end
    end

    describe 'when a project name is specified via ENV["to"]' do
      before do
        ENV['to'] = @env = 'whiskey_disk:staging'
      end
    
      describe 'when a project name is not specified in the bare config hash' do
        it 'should return the original data if it has both project and environment scoping' do
          @config.add_project_scoping(@proj_data).should == @proj_data
        end
    
        it 'should return the original data wrapped in project scope if it has environment scoping but no project scoping' do
          @config.add_project_scoping(@bare_data).should == { 'whiskey_disk' => @bare_data }
        end
      end
    
      describe 'when a project name is specified in the bare config hash' do
        before do
          @bare_data['staging']['project'] = 'whiskey_disk'
        end
    
        it 'should return the original data if it has both project and environment scoping' do
          @config.add_project_scoping(@proj_data).should == @proj_data
        end
    
        it 'should return the original data wrapped in project scope if it has environment scoping but no project scoping' do
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
  
    it 'should set the domain to "local" when no domain is specified' do
      @config.normalize_domains(@data)['foo']['xyz']['domain'].should == [ { :name => 'local' } ]   
    end
    
    it 'should handle nil domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['xyz']['domain'].should == [ { :name => 'local' } ]
    end
  
    it 'should return domain as "local" if a single empty domain was specified' do
      @config.normalize_domains(@data)['foo']['eee']['domain'].should == [ { :name => 'local' } ]
    end
    
    it 'should handle single empty specified domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['eee']['domain'].should == [ { :name => 'local' } ]                 
    end
    
    it 'should return domain as a single element list with a name if a single non-empty domain was specified' do
      @config.normalize_domains(@data)['foo']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
    end
    
    it 'should handle single specified domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['abc']['domain'].should == [ { :name => 'what@example.com' } ]
    end
  
    it 'should return the list of domain name hashes when a list of domains is specified' do
      @config.normalize_domains(@data)['foo']['baz']['domain'].should == [ 
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
      ]
    end
  
    it 'should handle lists of domains across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['hij']['domain'].should == [ 
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' } 
       ]
    end
    
    it 'should replace any nil domains with "local" domains in a domain list' do
      @config.normalize_domains(@data)['foo']['bar']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
       ]
    end
    
    it 'should handle localizing nils across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['def']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'local' }, { :name => 'foo@domain.com' }
       ]
    end
    
    it 'should replace any blank domains with "local" domains in a domain list' do
      @config.normalize_domains(@data)['foo']['bat']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
       ]
    end
    
    it 'should handle localizing blanks across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['dex']['domain'].should == [
        { :name => 'user@example.com' }, { :name => 'foo@domain.com' }, { :name => 'local' }
       ]
    end
    
    it 'should not include roles when only nil, blank or empty roles lists are specified' do
      @config.normalize_domains(@data)['foo']['erl']['domain'].should == [
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
       ]        
    end
  
    it 'should handle filtering empty roles across all projects and targets ' do
      @config.normalize_domains(@data)['zyx']['erl']['domain'].should == [
        { :name => 'bar@example.com' }, { :name => 'baz@domain.com' }, { :name => 'aok@domain.com' }
       ]        
    end
    
    it 'should include and normalize roles when specified as strings or lists' do
      @config.normalize_domains(@data)['foo']['rol']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
  
    it 'should handle normalizing roles across all projects and targets ' do
      @config.normalize_domains(@data)['zyx']['rol']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
    
    it 'should respect empty domains among role data' do
      @config.normalize_domains(@data)['foo']['wow']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'local' },
        { :name => 'foo@bar.example.com' },
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]                
    end
    
    it 'should handle empty domain filtering among roles across all projects and targets' do
      @config.normalize_domains(@data)['zyx']['wow']['domain'].should == [
        { :name => 'bar@example.com', :roles => [ 'web', 'db' ] }, 
        { :name => 'baz@domain.com',  :roles => [ 'db' ] }, 
        { :name => 'local' },
        { :name => 'foo@bar.example.com' },
        { :name => 'aok@domain.com',  :roles => [ 'app' ] }
       ]        
    end
    
    it 'should raise an exception if a domain appears more than once in a target' do
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

  describe 'by checking for project and environment' do
  
  end

  describe 'by adding the environment name' do
  
  end

  describe 'by adding the project name' do
  
  end

  describe 'by defaulting the config target' do
  
  end
end
    

