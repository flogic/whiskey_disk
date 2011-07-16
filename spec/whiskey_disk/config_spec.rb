require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'config'))

describe WhiskeyDisk::Config do
  before do
    @config = WhiskeyDisk::Config.new
  end

  describe 'when determining the environment name' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the environment name stored in the fetched configuration' do
      environment_name = 'fake env name'
      @config.stub!(:fetch).and_return({ 'environment' => environment_name })
      @config.environment_name.should == environment_name
    end
  end
  
  describe 'when determining the project name' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the project name stored in the fetched configuration' do
      project_name = 'fake project name'
      @config.stub!(:fetch).and_return({ 'project' => project_name })
      @config.project_name.should == project_name
    end
  end
  
  describe 'when determining whether there is a domain limit set' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      domain_limit = 'fake domain limit'
      @environment.stub!(:domain_limit).and_return(domain_limit)
      @config.domain_limit.should == domain_limit
    end
  end
  
  describe 'when determining whether debug mode is on' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      debugging = 'fake debug setting'
      @environment.stub!(:debug?).and_return(debugging)
      @config.debug?.should == debugging
    end    
  end

  describe 'when determining whether staleness checking is on' do
    before do
      @environment = WhiskeyDisk::Config::Environment.new
      WhiskeyDisk::Config::Environment.stub!(:new).and_return(@environment)
    end
    
    it 'returns the value set in the environment' do
      checking = 'fake staleness checking'
      @environment.stub!(:check_staleness?).and_return(checking)
      @config.check_staleness?.should == checking
    end    
  end
  
  describe 'when fetching configuration' do
    it 'returns the configuration data returned from the reader' do
      @result = 'fake config fetch result'
      @reader = WhiskeyDisk::Config::Reader.new(@environment)
      @reader.stub!(:fetch).and_return(@result)
      WhiskeyDisk::Config::Reader.stub!(:new).and_return(@reader)
      @config.fetch.should == @result
    end
  end  

end
