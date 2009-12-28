require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))
require 'whiskey_disk'

describe 'requiring the main library' do
  it 'should make a configuration loading task available' do
    Rake::Task.task_defined?('deploy:load_configuration').should.be.true
  end

  it 'should make the deploy:setup rake task available' do
    Rake::Task.task_defined?('deploy:setup').should.be.true
  end

  it 'should make the deploy:now rake task available' do
    Rake::Task.task_defined?('deploy:now').should.be.true
  end

  it 'should make the deploy:refresh rake task available' do
    Rake::Task.task_defined?('deploy:refresh').should.be.true
  end
end

describe 'rake tasks' do
  describe 'deploy:load_configuration' do
    it 'should fetch the configuration' do
      WhiskeyDisk::Config.should.receive(:fetch).and_return({ :destination => 'abc' })
      Rake::Task['deploy:load_configuration'].invoke
    end
    
    it 'should make the configuration data available as method calls' do
      WhiskeyDisk::Config.stub!(:fetch).and_return({ :destination => 'abc' })
      Rake::Task['deploy:load_configuration'].invoke
      destination.should == 'abc'
    end
  end
  
  describe 'deploy:setup' do
    
  end
  
  describe 'deploy:now' do
    
  end
  
  describe 'deploy:refresh' do
    
  end
end
