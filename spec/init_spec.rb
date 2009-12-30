require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require 'rake'

describe 'when the init.rb plugin loader has been included' do
  it 'should load the main library' do
    require(File.expand_path(File.join(File.dirname(__FILE__), '..', 'init')))
    $".should.include(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'whiskey_disk.rb')))
  end
end
