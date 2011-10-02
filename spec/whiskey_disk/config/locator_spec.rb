require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'locator'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'whiskey_disk', 'config', 'environment'))

describe WhiskeyDisk::Config::Locator do
  before do
    @environment = WhiskeyDisk::Config::Environment.new
    @locator = WhiskeyDisk::Config::Locator.new(@environment)
  end

  describe 'computing the base path for the project' do
    before do
      @original_path = Dir.pwd
      ENV['path'] = @path = nil
    end

    after do
      Dir.chdir(@original_path)
    end

    describe 'and a "path" environment variable is set' do
      before do
        ENV['path'] = @path = build_temp_dir
        @original_path = Dir.pwd
      end

      after do
        FileUtils.rm_rf(@path)
        Dir.chdir(@original_path)
      end

      it 'returns the path set in the "path" environment variable' do
        @locator.base_path.should == @path
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        @locator.base_path
        Dir.pwd.should == @original_path
      end
    end

    describe 'and there is no Rakefile in the root path to the current directory' do
      before do
        @original_path = Dir.pwd
        @path = build_temp_dir
        Dir.chdir(@path)
      end

      after do
        Dir.chdir(@original_path)
        FileUtils.rm_rf(@path)
      end

      it 'returns the config directory under the current directory if there is no Rakefile along the root path to the current directory' do
        @locator.base_path.should == File.join(@path, 'config')
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        @locator.base_path
        Dir.pwd.should == prior
      end
    end

    describe 'and there is a Rakefile in the root path to the current directory' do
      before do
        @original_path = Dir.pwd
        @path = build_temp_dir
        Dir.chdir(@path)
        FileUtils.touch(File.join(@path, 'Rakefile'))
      end

      after do
        Dir.chdir(@original_path)
        FileUtils.rm_rf(@path)
      end

      it 'return the config directory in the nearest enclosing path with a Rakefile along the root path to the current directory' do
        @locator.base_path.should == File.join(@path, 'config')
      end

      it 'leaves the current working path the same as when the base path lookup started' do
        prior = Dir.pwd
        @locator.base_path
        Dir.pwd.should == prior
      end
    end
  end

  describe 'finding the configuration file' do
    before do
      ENV['to'] = @env = 'staging'
    end

    describe 'and no path is specified' do
      before do
        ENV['path'] = @path = nil
        @original_path = Dir.pwd
        @base_path = build_temp_dir
        Dir.chdir(@base_path)
        FileUtils.touch(File.join(@base_path, 'Rakefile'))
        @dir = File.join(@base_path, 'config')
        Dir.mkdir(@dir)

        [
          "/deploy/foo/staging.yml",
          "/deploy/foo.yml",
          "/deploy/staging.yml",
          "/staging.yml",
          "/deploy.yml"
        ].each { |file| make(File.join(@dir, file)) }
      end

      after do
        FileUtils.rm_rf(@base_path)
        Dir.chdir(@original_path)
      end

      describe 'and a project name is specified in ENV["to"]' do
        before do
          ENV['to'] = @env = 'foo:staging'
        end

        it 'returns the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          @locator.location.should == "#{@dir}/deploy/foo/staging.yml"
        end

        it 'returns the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          @locator.location.should == "#{@dir}/deploy/foo.yml"
        end

        it 'returns the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          @locator.location.should == "#{@dir}/deploy/staging.yml"
        end

        it 'returns the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          @locator.location.should == "#{@dir}/staging.yml"
        end

        it 'returns the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          @locator.location.should == "#{@dir}/deploy.yml"
        end

        it 'fails if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/foo/staging.yml")
          File.unlink("#{@dir}/deploy/foo.yml")
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { @locator.location }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'returns the path to a per-environment configuration file in the deploy/ directory under the project base path if it exists' do
          @locator.location.should == "#{@dir}/deploy/staging.yml"
        end

        it 'returns the path to a per-environment configuration file under the project base path if it exists' do
          File.unlink("#{@dir}/deploy/staging.yml")
          @locator.location.should == "#{@dir}/staging.yml"
        end

        it 'returns the path to deploy.yml under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          @locator.location.should == "#{@dir}/deploy.yml"
        end

        it 'fails if no per-environment config file nor deploy.yml exists under the project base path' do
          File.unlink("#{@dir}/deploy/staging.yml")
          File.unlink("#{@dir}/staging.yml")
          File.unlink("#{@dir}/deploy.yml")
          lambda { @locator.location }.should.raise
        end
      end
    end

    describe 'and looking up a file' do
      before do
        @path = build_temp_dir
        ENV['path'] = @locator_file = File.join(@path, 'deploy.yml')
      end

      after do
        FileUtils.rm_rf(@path)
      end

      it 'fails if a path is specified which does not exist' do
        lambda { @locator.location }.should.raise
      end

      it 'returns the file path when a path which points to an existing file is specified' do
        FileUtils.touch(@locator_file)
        @locator.location.should == @locator_file
      end
    end

    describe 'and a path which points to a directory is specified' do
      before do
        ENV['path'] = @path = build_temp_dir

        [
          "/deploy/foo/staging.yml",
          "/deploy/foo.yml",
          "/deploy/staging.yml",
          "/staging.yml",
          "/deploy.yml"
        ].each { |file| make(File.join(@path, file)) }
      end

      after do
        FileUtils.rm_rf(@path)
      end

      describe 'and a project name is specified in ENV["to"]' do
        before do
          ENV['to'] = @env = 'foo:staging'
        end

        it 'returns the path to deploy/foo/<environment>.yml under the project base path if it exists' do
          @locator.location.should == File.join(@path, 'deploy', 'foo' ,'staging.yml')
        end

        it 'returns the path to deploy/foo.yml under the project base path if it exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          @locator.location.should == File.join(@path, 'deploy', 'foo.yml')
        end

        it 'returns the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          @locator.location.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'returns the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          @locator.location.should == File.join(@path, 'staging.yml')
        end

        it 'returns the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          @locator.location.should == File.join(@path, 'deploy.yml')
        end

        it 'fails if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'foo', 'staging.yml'))
          File.unlink(File.join(@path, 'deploy', 'foo.yml'))
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { @locator.location }.should.raise
        end
      end

      describe 'and no project name is specified in ENV["to"]' do
        it 'returns the path to a per-environment configuration file under deploy/ in the path specified if that file exists' do
          @locator.location.should == File.join(@path, 'deploy', 'staging.yml')
        end

        it 'returns the path to a per-environment configuration file in the path specified if that file exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          @locator.location.should == File.join(@path, 'staging.yml')
        end

        it 'returns the path to deploy.yaml in the path specified if deploy.yml exists' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          @locator.location.should == File.join(@path, 'deploy.yml')
        end

        it 'fails if no per-environment configuration file nor deploy.yml exists in the path specified' do
          File.unlink(File.join(@path, 'deploy', 'staging.yml'))
          File.unlink(File.join(@path, 'staging.yml'))
          File.unlink(File.join(@path, 'deploy.yml'))
          lambda { @locator.location }.should.raise
        end
      end
    end
  end
end