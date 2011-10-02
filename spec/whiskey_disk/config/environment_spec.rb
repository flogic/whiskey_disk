require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'environment'))

describe WhiskeyDisk::Config::Environment do
  before do
    @environment = WhiskeyDisk::Config::Environment.new
  end

  describe 'when computing the environment name' do
    it 'returns false when there is no ENV["to"] setting' do
      ENV['to'] = nil
      @environment.environment_name.should == false
    end

    it 'returns false when the ENV["to"] setting is blank' do
      ENV['to'] = ''
      @environment.environment_name.should == false
    end

    it 'returns the ENV["to"] setting when it is non-blank' do
      ENV['to'] = 'staging'
      @environment.environment_name.should == 'staging'
    end

    it 'returns the environment portion of the ENV["to"] setting when a project is specified' do
      ENV['to'] = 'project:staging'
      @environment.environment_name.should == 'staging'
    end
  end

  describe 'when computing the project name' do
    it 'returns the project name from the ENV["to"] setting when it is available' do
      ENV['to'] = 'foo:staging'
      @environment.project_name.should == 'foo'
    end

    it 'returns "unnamed_project" when ENV["to"] is unset' do
      ENV['to'] = ''
      @environment.project_name.should == 'unnamed_project'
    end

    it 'returns "unnamed_project" when no ENV["to"] project setting is available' do
      ENV['to'] = 'staging'
      @environment.project_name.should == 'unnamed_project'
    end
  end

  describe 'when determining whether there is a domain limit set' do
    it 'returns false when ENV["only"] is nil' do
      ENV['only'] = nil
      @environment.domain_limit.should == false
    end

    it 'returns false when ENV["only"] is empty' do
      ENV['only'] = ''
      @environment.domain_limit.should == false
    end

    it 'returns the value in ENV["only"] when it is non-empty' do
      ENV['only'] = 'somedomain'
      @environment.domain_limit.should == 'somedomain'
    end
  end

  describe 'when determining whether to turn debug mode on' do
    it 'returns false when there is no ENV["debug"] setting' do
      ENV['debug'] = nil
      @environment.debug?.should == false
    end

    it 'returns false when the ENV["debug"] setting is blank' do
      ENV['debug'] = ''
      @environment.debug?.should == false
    end

    it 'returns true if the ENV["debug"] setting is "t"' do
      ENV['debug'] = 't'
      @environment.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "true"' do
      ENV['debug'] = 'true'
      @environment.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "y"' do
      ENV['debug'] = 'y'
      @environment.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "yes"' do
      ENV['debug'] = 'yes'
      @environment.debug?.should == true
    end

    it 'returns true if the ENV["debug"] setting is "1"' do
      ENV['debug'] = '1'
      @environment.debug?.should == true
    end
  end

  describe 'when determining whether to do a staleness check before updating' do
    it 'returns false when there is no ENV["check"] setting' do
      ENV['check'] = nil
      @environment.check_staleness?.should == false
    end

    it 'returns false when the ENV["check"] setting is blank' do
      ENV['check'] = ''
      @environment.check_staleness?.should == false
    end

    it 'returns true if the ENV["check"] setting is "t"' do
      ENV['check'] = 't'
      @environment.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "true"' do
      ENV['check'] = 'true'
      @environment.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "y"' do
      ENV['check'] = 'y'
      @environment.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "yes"' do
      ENV['check'] = 'yes'
      @environment.check_staleness?.should == true
    end

    it 'returns true if the ENV["check"] setting is "1"' do
      ENV['check'] = '1'
      @environment.check_staleness?.should == true
    end
  end
end