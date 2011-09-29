require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'default_domain_filter'))

describe 'setting empty domain entries to "local"' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::DefaultDomainFilter.new(@config)
  end
  
  it 'leaves data intact if it has a domain' do
    @filter.filter({ 'domain' => 'anything' }).should == { 'domain' => 'anything' }
  end

  it 'adds a local domain entry if data does not have a domain' do
    @filter.filter({}).should == { 'domain' => [{ 'name' => 'local' }] }
  end
end