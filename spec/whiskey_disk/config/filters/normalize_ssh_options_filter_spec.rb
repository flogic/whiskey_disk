require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'normalize_ssh_options_filter'))

describe 'normalizing SSH options' do
  before do
    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::NormalizeSshOptionsFilter.new(@config)
  end

  it 'eliminates ssh options with nil, or empty values' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'ssh_options' => nil },
        { 'name' => 'bar', 'ssh_options' => '' },
        { 'name' => 'baz', 'ssh_options' => [] },
        { 'name' => 'xyzzy', 'ssh_options' => ['', ''] },
        { 'name' => 'quux', 'ssh_options' => [nil, '', nil] },
      ]
    }

    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' },
        { 'name' => 'xyzzy' },
        { 'name' => 'quux' }
      ]
    }
  end

  it 'preserves non-empty ssh options' do
    @data = {
      'domain' => [
        { 'name' => 'foo', 'ssh_options' => nil },
        { 'name' => 'bar', 'ssh_options' => 'c' },
        { 'name' => 'baz', 'ssh_options' => [] },
        { 'name' => 'xyzzy', 'ssh_options' => ['', 'c'] },
        { 'name' => 'quux', 'ssh_options' => [nil, '', 'a', nil, 'b' ] },
        { 'name' => 'wut', 'ssh_options' => [nil, '', 'x', 'a', 'a', nil, 'b' ] },
      ]
    }

    @filter.filter(@data).should == {
      'domain' => [
        { 'name' => 'foo' },
        { 'name' => 'bar', 'ssh_options' => [ 'c' ] },
        { 'name' => 'baz' },
        { 'name' => 'xyzzy', 'ssh_options' => [ 'c' ] },
        { 'name' => 'quux', 'ssh_options' => [ 'a', 'b' ] },
        { 'name' => 'wut', 'ssh_options' => [ 'x', 'a', 'a', 'b' ] }
      ]
    }
  end
end