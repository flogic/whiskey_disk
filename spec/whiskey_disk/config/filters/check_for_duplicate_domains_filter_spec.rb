require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'check_for_duplicate_domains_filter'))

describe 'filtering configuration data by normalizing domains' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::CheckForDuplicateDomainsFilter.new(@config)
  end

  it 'should return the suuplied data if no domains appear more than once in a target' do
    @data = {
      'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil },
                                         { 'name' => 'baz@domain.com',  'roles' => '' } ]
    }

    @filter.filter(@data).should == @data
  end

  it 'raises an exception if a domain appears more than once in a target' do
    @data = {
      'repository' => 'x', 'domain' => [ { 'name' => 'bar@example.com', 'roles' => nil },
                                         { 'name' => 'baz@domain.com',  'roles' => '' },
                                         { 'name' => 'bar@example.com', 'roles' => [] } ]
    }

    lambda { @filter.filter(@data) }.should.raise
  end
end