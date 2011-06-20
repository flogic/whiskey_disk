require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require 'rake'

describe 'rake tasks' do
  before do
    Rake.application = @rake = Rake::Application.new
    load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'rake.rb'))
    @whiskey_disk = WhiskeyDisk.new
    WhiskeyDisk.stub!(:new).and_return(@whiskey_disk)
  end

  after do
    Rake.application = nil
  end
  
  describe 'deploy:setup' do
    before do
      @whiskey_disk.configuration = {}
      @whiskey_disk.stub!(:setup).and_return(true)
    end
    
    it 'runs a whiskey_disk setup' do
      @whiskey_disk.should.receive(:setup).and_return(true)
      @rake["deploy:setup"].invoke
    end
    
    it 'does not exit in error if all setup runs were successful' do
      lambda { @rake["deploy:setup"].invoke }.should.not.raise(SystemExit)
    end
    
    it 'exits in error if some setup run was unsuccessful' do
      @whiskey_disk.stub!(:setup).and_return(false)
      lambda { @rake["deploy:setup"].invoke }.should.raise(SystemExit)
    end
  end
    
  describe 'deploy:now' do
    before do
      @whiskey_disk.configuration = {}
      @whiskey_disk.stub!(:deploy).and_return(true)
    end
    
    it 'runs a whiskey_disk setup' do
      @whiskey_disk.should.receive(:deploy).and_return(true)
      @rake["deploy:now"].invoke
    end
    
    it 'does not exit in error if all setup runs were successful' do
      lambda { @rake["deploy:now"].invoke }.should.not.raise(SystemExit)
    end
    
    it 'exits in error if some setup run was unsuccessful' do
      @whiskey_disk.stub!(:deploy).and_return(false)
      lambda { @rake["deploy:now"].invoke }.should.raise(SystemExit)
    end
  end
      
  describe 'deploy:post_setup' do
    it 'runs the defined post_setup rake task when a post_setup rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'production'}

      task "deploy:production:post_setup" do
        @whiskey_disk.fake_method
      end

      @whiskey_disk.should.receive(:fake_method)
      Rake::Task['deploy:post_setup'].invoke
    end

    it 'does not fail when no post_setup rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'staging'}
      lambda { Rake::Task['deploy:post_setup'].invoke }.should.not.raise
    end
  end
  
  describe 'deploy:post_deploy' do
    it 'runs the defined post_deploy rake task when a post_deploy rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'production'}

      task "deploy:production:post_deploy" do
        @whiskey_disk.fake_method
      end

      @whiskey_disk.should.receive(:fake_method)
      Rake::Task['deploy:post_deploy'].invoke
    end

    it 'does not fail when no post_deploy rake task is defined for this environment' do
      @whiskey_disk.configuration = { 'environment' => 'staging'}
      lambda { Rake::Task['deploy:post_deploy'].invoke }.should.not.raise
    end
  end
end
