require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'localize_domains_filter'))

describe 'setting empty domain entries to "local"' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::LocalizeDomainsFilter.new(@config)
  end

  it 'handles empty domain filtering among roles across all projects and targets' do
    @data = {
      'domain' => [
        { 'name' => nil },
        { 'name' => '' },
        { 'name' => 'local' },
        { 'name' => 'x' }
      ]
    }

    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'local' },
        { 'name' => 'local' },
        { 'name' => 'local' },
        { 'name' => 'x' }
      ]
    }
  end
end