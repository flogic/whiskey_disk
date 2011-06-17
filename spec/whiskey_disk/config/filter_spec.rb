require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filter'))

describe WhiskeyDisk::Config::Filter, 'filtering configuration data' do
  before do
    ENV['to'] = @env = 'foo:erl'

    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::Filter.new(@config)

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
    @filter.filter_data(@data).should == {
      'repository'    => "x", 
      'project'       => "foo", 
      'config_target' => "erl", 
      'environment'   => "erl",
      'domain'        => [ 
        { 'name' => "bar@example.com" }, 
        { 'name' => "baz@domain.com" }, 
        { 'name' => "aok@domain.com" }
      ]
    }
  end
end

