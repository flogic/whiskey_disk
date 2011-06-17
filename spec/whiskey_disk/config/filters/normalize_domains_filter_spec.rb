require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'normalize_domains_filter'))

describe 'filtering configuration data by normalizing domains' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::NormalizeDomainsFilter.new(@config)
    
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

  it 'does not include roles when only nil, blank or empty roles lists are specified' do
    @filter.filter(@data['foo']['erl'])['domain'].should == [
      { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' }, { 'name' => 'aok@domain.com' }
     ]        
  end

  it 'handles filtering empty roles across all projects and targets ' do
    @filter.filter(@data['zyx']['erl'])['domain'].should == [
      { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' }, { 'name' => 'aok@domain.com' }
     ]        
  end
  
  it 'includes and normalizes roles when specified as strings or lists' do
    @filter.filter(@data['foo']['rol'])['domain'].should == [
      { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
      { 'name' => 'baz@domain.com',  'roles' => [ 'db' ] }, 
      { 'name' => 'aok@domain.com',  'roles' => [ 'app' ] }
     ]        
  end

  it 'handles normalizing roles across all projects and targets ' do
    @filter.filter(@data['zyx']['rol'])['domain'].should == [
      { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
      { 'name' => 'baz@domain.com',  'roles' => [ 'db' ] }, 
      { 'name' => 'aok@domain.com',  'roles' => [ 'app' ] }
     ]        
  end
end