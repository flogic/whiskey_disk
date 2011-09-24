require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'filters', 'project_scope_filter'))

describe 'filtering configuration data by adding project scoping' do
  before do
    ENV['to'] = @env = 'foo:staging'

    @config = WhiskeyDisk::Config.new
    @filter = WhiskeyDisk::Config::ProjectScopeFilter.new(@config)

    @bare_data  = { 'staging' => { 'repository' => 'git://foo/bar.git', 'domain' => [ { :name => 'ogc@ogtastic.com' } ] } }
    @proj_data  = { 'foo' => @bare_data }
  end

  it 'fails if the configuration data is not a hash' do
    lambda { @filter.filter([]) }.should.raise
  end

  describe 'when no project name is specified via ENV["to"]' do
    before do
      ENV['to'] = @env = 'staging'
    end

    it 'returns the original data if it has both project and environment scoping' do
      @filter.filter(@proj_data).should == @proj_data
    end

    describe 'when no project name is specified in the bare config hash' do
      it 'returns the original data wrapped in project scope, using a dummy project, if it has environment scoping but no project scoping' do
        @filter.filter(@bare_data).should == { 'unnamed_project' => @bare_data }
      end
    end

    describe 'when a project name is specified in the bare config hash' do
      before do
        @bare_data['staging']['project'] = 'whiskey_disk'
      end

      it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
        @filter.filter(@bare_data).should == { 'whiskey_disk' => @bare_data }
      end
    end
  end

  describe 'when a project name is specified via ENV["to"]' do
    before do
      ENV['to'] = @env = 'whiskey_disk:staging'
    end
  
    describe 'when a project name is not specified in the bare config hash' do
      it 'returns the original data if it has both project and environment scoping' do
        @filter.filter(@proj_data).should == @proj_data
      end
  
      it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
        @filter.filter(@bare_data).should == { 'whiskey_disk' => @bare_data }
      end
    end
  
    describe 'when a project name is specified in the bare config hash' do
      before do
        @bare_data['staging']['project'] = 'whiskey_disk'
      end
  
      it 'returns the original data if it has both project and environment scoping' do
        @filter.filter(@proj_data).should == @proj_data
      end
  
      it 'returns the original data wrapped in project scope if it has environment scoping but no project scoping' do
        @filter.filter(@bare_data).should == { 'whiskey_disk' => @bare_data }
      end
    end
  end 
end
