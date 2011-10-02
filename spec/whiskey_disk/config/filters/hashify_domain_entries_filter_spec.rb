require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'hashify_domain_entries_filter'))

describe 'setting empty domain entries to "local"' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::HashifyDomainEntriesFilter.new(@config)
  end

  it 'handles empty domain filtering among roles across all projects and targets' do
    @data = {
      'domain' => [
        'x',
        nil,
        { 'name' => 'foo', 'roles' => ['x', 'y'] },
        '',
        'local'
      ]
    }

    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'x' },
        { 'name' => nil },
        { 'name' => 'foo', 'roles' => ['x', 'y'] },
        { 'name' => '' },
        { 'name' => 'local' }
      ]
    }
  end

  it 'handles the degenerate case of a single domain name' do
    @data = { 'domain' => 'foo' }
    @filter.filter(@data).should == { 'domain' => [ { 'name' => 'foo' } ] }
  end

  it 'handles the degenerate case of no domain specified' do
    @filter.filter({}).should == { 'domain' => { 'name' => '' } }
  end
end