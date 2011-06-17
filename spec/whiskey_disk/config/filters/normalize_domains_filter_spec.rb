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

  it 'sets the domain to "local" when no domain is specified' do
    @filter.filter(@data['foo']['xyz'])['domain'].should == [ { 'name' => 'local' } ]   
  end
  
  it 'handles nil domains across all projects and targets' do
    @filter.filter(@data['zyx']['xyz'])['domain'].should == [ { 'name' => 'local' } ]
  end

  it 'returns domain as "local" if a single empty domain was specified' do
    @filter.filter(@data['foo']['eee'])['domain'].should == [ { 'name' => 'local' } ]
  end
  
  it 'handles single empty specified domains across all projects and targets' do
    @filter.filter(@data['zyx']['eee'])['domain'].should == [ { 'name' => 'local' } ]                 
  end
  
  it 'returns domain as a single element list with a name if a single non-empty domain was specified' do
    @filter.filter(@data['foo']['abc'])['domain'].should == [ { 'name' => 'what@example.com' } ]
  end
  
  it 'handles single specified domains across all projects and targets' do
    @filter.filter(@data['zyx']['abc'])['domain'].should == [ { 'name' => 'what@example.com' } ]
  end

  it 'returns the list of domain name hashes when a list of domains is specified' do
    @filter.filter(@data['foo']['baz'])['domain'].should == [ 
      { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' } 
    ]
  end

  it 'handles lists of domains across all projects and targets' do
    @filter.filter(@data['zyx']['hij'])['domain'].should == [ 
      { 'name' => 'bar@example.com' }, { 'name' => 'baz@domain.com' } 
     ]
  end
  
  it 'replaces any nil domains with "local" domains in a domain list' do
    @filter.filter(@data['foo']['bar'])['domain'].should == [
      { 'name' => 'user@example.com' }, { 'name' => 'local' }, { 'name' => 'foo@domain.com' }
     ]
  end
  
  it 'handles localizing nils across all projects and targets' do
    @filter.filter(@data['zyx']['def'])['domain'].should == [
      { 'name' => 'user@example.com' }, { 'name' => 'local' }, { 'name' => 'foo@domain.com' }
     ]
  end
  
  it 'replaces any blank domains with "local" domains in a domain list' do
    @filter.filter(@data['foo']['bat'])['domain'].should == [
      { 'name' => 'user@example.com' }, { 'name' => 'foo@domain.com' }, { 'name' => 'local' }
     ]
  end
  
  it 'handles localizing blanks across all projects and targets' do
    @filter.filter(@data['zyx']['dex'])['domain'].should == [
      { 'name' => 'user@example.com' }, { 'name' => 'foo@domain.com' }, { 'name' => 'local' }
     ]
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
  
  it 'respects empty domains among role data' do
    @filter.filter(@data['foo']['wow'])['domain'].should == [
      { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
      { 'name' => 'baz@domain.com',  'roles' => [ 'db' ] }, 
      { 'name' => 'local' },
      { 'name' => 'foo@bar.example.com' },
      { 'name' => 'aok@domain.com',  'roles' => [ 'app' ] }
     ]                
  end
  
  it 'handles empty domain filtering among roles across all projects and targets' do
    @filter.filter(@data['zyx']['wow'])['domain'].should == [
      { 'name' => 'bar@example.com', 'roles' => [ 'web', 'db' ] }, 
      { 'name' => 'baz@domain.com',  'roles' => [ 'db' ] }, 
      { 'name' => 'local' },
      { 'name' => 'foo@bar.example.com' },
      { 'name' => 'aok@domain.com',  'roles' => [ 'app' ] }
     ]        
  end
end