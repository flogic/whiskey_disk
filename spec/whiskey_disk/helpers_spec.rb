require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'helpers'))

describe 'when checking for a role during setup or deployment' do
  it 'should accept a role string' do
    lambda { role?('web') }.should.not.raise(ArgumentError)
  end
  
  it 'should require a role string' do
    lambda { role? }.should.raise(ArgumentError)
  end

  it 'should return false if the WD_ROLES environment variable is unset' do
    ENV['WD_ROLES'] = nil
    role?(:web).should.be.false
  end

  it 'should return false if the WD_ROLES environment variable is empty' do
    ENV['WD_ROLES'] = ''
    role?(:web).should.be.false
  end
  
  it 'should return true if the role, as a symbol is among the roles in the WD_ROLES env variable' do
    ENV['WD_ROLES'] = 'db:web'
    role?(:db).should.be.true
  end
  
  it 'should return true if the role, as a string is among the roles in the WD_ROLES env variable' do
    ENV['WD_ROLES'] = 'db:web'
    role?('db').should.be.true
  end
  
  it 'should return false if the role, as a symbol is not among the roles in the WD_ROLES env variable' do
    ENV['WD_ROLES'] = 'db:web'
    role?(:app).should.be.false
  end
  
  it 'should return false if the role, as a string is not among the roles in the WD_ROLES env variable' do
    ENV['WD_ROLES'] = 'db:web'
    role?('app').should.be.false
  end
end

def set_git_changes(changes)
  self.stub!(:git_changes).and_return(changes)
end

def set_rsync_changes(changes)
  self.stub!(:rsync_changes).and_return(changes)
end

describe 'when determining if certain files changed when a deployment was run' do
  before do
    @matching_file     = '/path/to/file'
    @matching_path     = '/path/to'
    @non_matching_file = '/nowhere/file'
    @substring_file    = '/nowhere/filething'
    @random_file       = '/random/path'
    
    set_git_changes([])
    set_rsync_changes([])
  end
  
  it 'should accept a path' do
    lambda { changed?('foo') }.should.not.raise(ArgumentError)
  end
  
  it 'should require a path' do
    lambda { changed? }.should.raise(ArgumentError)
  end
  
  it 'should be true when the specified file is in the list of git changes' do
    set_git_changes([ @matching_file, @random_file])
    changed?(@matching_file).should.be.true
  end
  
  it 'should ignore trailing "/"s in the provided path when doing an exact git change match' do
    set_git_changes([ @matching_file, @random_file])
    changed?(@matching_file + '///').should.be.true    
  end
  
  it 'should be true when the specified path is a full path prefix in the list of git changes' do
    set_git_changes([ @matching_file , @random_file])
    changed?(@matching_path).should.be.true    
  end
  
  it 'should ignore trailing "/"s in the provided path when doing a path git change match' do
    set_git_changes([ @matching_file , @random_file])
    changed?(@matching_path + '///').should.be.true    
  end

  it 'should be true when the specified file is in the list of rsync changes' do    
    set_rsync_changes([ @matching_file, @random_file])
    changed?(@matching_file).should.be.true
  end

  it 'should ignore trailing "/"s in the provided path when doing an exact rsync change match' do
    set_rsync_changes([ @matching_file, @random_file])
    changed?(@matching_file + "///").should.be.true
  end

  it 'should be true when the specified path is a full path prefix in the list of git changes' do
    set_rsync_changes([ @matching_file , @random_file])
    changed?(@matching_path).should.be.true    
  end
  
  it 'should ignore trailing "/"s in the provided path when doing a path rsync change match' do
    set_rsync_changes([ @matching_file , @random_file])
    changed?(@matching_path + '///').should.be.true    
  end
  
  it 'should ignore regex metacharacters when looking for a git match' do
    set_git_changes([ '/path/to/somestring'])
    changed?('/path/to/some.*').should.be.false
  end
  
  it 'should ignore regex metacharacters when looking for an rsync match' do
    set_rsync_changes([ '/path/to/somestring'])
    changed?('/path/to/some.*').should.be.false
  end
  
  it 'should be true when the git changes file cannot be found' do
    set_git_changes(nil)
    changed?(@matching_file).should.be.true    
  end
  
  it 'should be false if not path or file matches the specified file' do
    set_git_changes([@matching_file, @matching_path, @random_file, @substring_file])
    set_rsync_changes([@matching_file, @matching_path, @random_file, @substring_file])
    changed?(@non_matching_file).should.be.false
  end
end

describe "when finding files changed by git in a deployment" do
  before do
    @contents = 'CHANGELOG
README.markdown
Rakefile
VERSION
lib/whiskey_disk.rb
lib/whiskey_disk/config.rb
lib/whiskey_disk/helpers.rb
scenarios/git_repositories/project.git/objects/04/26e152e66c8cd42974279bdcae09be9839c172
scenarios/git_repositories/project.git/objects/04/f4de85eaf72ef1631dc6d7424045c0a749b757
scenarios/git_repositories/project.git/refs/heads/bad_rakefile
scenarios/git_repositories/project.git/refs/heads/master
scenarios/remote/deploy.yml
spec/integration/deployment_failures_spec.rb
spec/integration/post_rake_tasks_spec.rb
spec/integration/staleness_checks_spec.rb
spec/spec_helper.rb
spec/whiskey_disk/config_spec.rb
spec/whiskey_disk/helpers_spec.rb
spec/whiskey_disk_spec.rb
whiskey_disk.gemspec
'   
  end
    
  it 'should work without arguments' do
    lambda { git_changes }.should.not.raise(ArgumentError)
  end
  
  it 'should not allow arguments' do
    lambda { git_changes(:foo) }.should.raise(ArgumentError)
  end
  
  it 'should return nil when a git changes file cannot be found' do
    self.stub!(:read_git_changes_file).and_raise
    git_changes.should.be.nil
  end
  
  it 'should return an empty list if no files are found in the git changes file' do
    self.stub!(:read_git_changes_file).and_return('')
    git_changes.should == []
  end
  
  it 'should return a list of all filenames mentioned in the git changes file' do
    self.stub!(:read_git_changes_file).and_return(@contents)
    git_changes.should == @contents.split("\n")
  end
  
  it 'should strip duplicates from filenames mentioned in the git changes file' do
    lines = @contents.split("\n")
    duplicates = @contents + lines.first + "\n" + lines.last + "\n"
    self.stub!(:read_git_changes_file).and_return(duplicates)
    git_changes.sort.should == @contents.split("\n").sort
  end
end

describe "when finding files changed by rsync in a deployment" do
  before do
    @contents = '2011/02/27 20:11:42 [36728] receiving file list
2011/02/27 20:11:42 [36728] sent 24 bytes  received 9 bytes  total size 0
2011/02/27 20:11:58 [36780] receiving file list
2011/02/27 20:11:58 [36780] sent 24 bytes  received 9 bytes  total size 0
2011/02/27 20:12:09 [36808] receiving file list
2011/02/27 20:12:09 [36808] sent 24 bytes  received 9 bytes  total size 0
2011/02/27 20:12:19 [36835] receiving file list
2011/02/27 20:12:19 [36835] .d..t.... ./
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/
2011/02/27 20:12:19 [36835] >f+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Info.plist
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/
2011/02/27 20:12:19 [36835] cL+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/GoogleBreakpad -> Versions/Current/GoogleBreakpad
2011/02/27 20:12:19 [36835] cL+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Resources -> Versions/Current/Resources
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/
2011/02/27 20:12:19 [36835] cL+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/Current -> A
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources/Reporter.app/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources/Reporter.app/Contents/
2011/02/27 20:12:19 [36835] cd+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/MacOS/
2011/02/27 20:12:20 [36835] >f+++++++ Application Support/Google/GoogleTalkPlugin.app/Contents/MacOS/GoogleTalkPlugin
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/googletalkbrowserplugin.plugin/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/MacOS/
2011/02/27 20:12:20 [36835] >f+++++++ Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/MacOS/googletalkbrowserplugin
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/Resources/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/
2011/02/27 20:12:20 [36835] >f+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Info.plist
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/
2011/02/27 20:12:20 [36835] cL+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Cg -> Versions/Current/Cg
2011/02/27 20:12:20 [36835] cL+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Resources -> Versions/Current/Resources
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions/
2011/02/27 20:12:20 [36835] cL+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions/Current -> 1.0
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions/1.0/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/MacOS/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Resources/
2011/02/27 20:12:20 [36835] cd+++++++ Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Resources/English.lproj/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 0.component/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 0.component/Contents/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 0.component/Contents/MacOS/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 0.component/Contents/Resources/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 1.component/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 1.component/Contents/
2011/02/27 20:12:20 [36835] >f+++++++ QuickTime/Google Camera Adapter 1.component/Contents/Info.plist
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 1.component/Contents/MacOS/
2011/02/27 20:12:20 [36835] cd+++++++ QuickTime/Google Camera Adapter 1.component/Contents/Resources/
2011/02/27 20:12:20 [36835] sent 386 bytes  received 1431 bytes  total size 5229466
'

    @changes = [
        "Application Support",
        "Application Support/Google",
        "Application Support/Google/GoogleTalkPlugin.app",
        "Application Support/Google/GoogleTalkPlugin.app/Contents",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/GoogleBreakpad -> Versions/Current/GoogleBreakpad",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Resources -> Versions/Current/Resources",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources/Reporter.app",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/A/Resources/Reporter.app/Contents",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Frameworks/GoogleBreakpad.framework/Versions/Current -> A",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/Info.plist",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/MacOS",
        "Application Support/Google/GoogleTalkPlugin.app/Contents/MacOS/GoogleTalkPlugin",
        "Internet Plug-Ins",
        "Internet Plug-Ins/googletalkbrowserplugin.plugin",
        "Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents",
        "Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/MacOS",
        "Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/MacOS/googletalkbrowserplugin",
        "Internet Plug-Ins/googletalkbrowserplugin.plugin/Contents/Resources",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Cg -> Versions/Current/Cg",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Resources -> Versions/Current/Resources",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions/1.0",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Frameworks/Cg.framework/Versions/Current -> 1.0",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Info.plist",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/MacOS",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Resources",
        "Internet Plug-Ins/npgtpo3dautoplugin.plugin/Contents/Resources/English.lproj",
        "QuickTime",
        "QuickTime/Google Camera Adapter 0.component",
        "QuickTime/Google Camera Adapter 0.component/Contents",
        "QuickTime/Google Camera Adapter 0.component/Contents/MacOS",
        "QuickTime/Google Camera Adapter 0.component/Contents/Resources",
        "QuickTime/Google Camera Adapter 1.component",
        "QuickTime/Google Camera Adapter 1.component/Contents",
        "QuickTime/Google Camera Adapter 1.component/Contents/Info.plist",
        "QuickTime/Google Camera Adapter 1.component/Contents/MacOS",
        "QuickTime/Google Camera Adapter 1.component/Contents/Resources",
      ]
  end

  it 'should work without arguments' do
    lambda { rsync_changes }.should.not.raise(ArgumentError)
  end

  it 'should not allow arguments' do
    lambda { rsync_changes(:foo) }.should.raise(ArgumentError)
  end

  it 'should return nil when an rsync changes file cannot be found' do
    self.stub!(:read_rsync_changes_file).and_raise
    rsync_changes.should.be.nil
  end

  it 'should return an empty list if no files are found in the rsync changes file' do
    self.stub!(:read_rsync_changes_file).and_return('')
    rsync_changes.should == []
  end

  it 'should return a list of all changed filenames mentioned in the rsync changes file, excluding "."' do
    self.stub!(:read_rsync_changes_file).and_return(@contents)
    rsync_changes.sort.first.should == @changes.sort.first
  end
end

describe 'when reading the git-related changes for a deployment' do
  before do
    @contents = 'git changes'
    @changes_path = '/path/to/git/changes'
    self.stub!(:git_changes_path).and_return(@changes_path)
    File.stub!(:read).with(@changes_path).and_return(@contents)
  end
  
  it 'should work without arguments' do
    lambda { read_git_changes_file }.should.not.raise(ArgumentError)
  end
  
  it 'should not allow arguments' do
    lambda { read_git_changes_file(:foo) }.should.raise(ArgumentError)
  end
  
  it 'should read the git changes file' do
    File.should.receive(:read) do |arg|
      arg.should == @changes_path
      @contents
    end
    read_git_changes_file
  end
  
  it 'should return the contents of the git changes file' do
    read_git_changes_file.should == @contents
  end
  
  it 'should fail if the git changes file cannot be read' do
    File.stub!(:read).with(@changes_path).and_raise(Errno::ENOENT)
    lambda { read_git_changes_file }.should.raise(Errno::ENOENT)
  end
end

describe 'when reading the rsync-related changes for a deployment' do
  before do
    @contents = 'rsync changes'
    @changes_path = '/path/to/rsync/changes'
    self.stub!(:rsync_changes_path).and_return(@changes_path)
    File.stub!(:read).with(@changes_path).and_return(@contents)
  end
  
  it 'should work without arguments' do
    lambda { read_rsync_changes_file }.should.not.raise(ArgumentError)
  end
  
  it 'should not allow arguments' do
    lambda { read_rsync_changes_file(:foo) }.should.raise(ArgumentError)
  end
  
  it 'should read the rsync changes file' do
    File.should.receive(:read) do |arg|
      arg.should == @changes_path
      @contents
    end
    read_rsync_changes_file
  end
  
  it 'should return the contents of the rsync changes file' do
    read_rsync_changes_file.should == @contents
  end
  
  it 'should fail if the rsync changes file cannot be read' do
    File.stub!(:read).with(@changes_path).and_raise(Errno::ENOENT)
    lambda { read_rsync_changes_file }.should.raise(Errno::ENOENT)
  end
end

describe 'computing the path to the git changes file' do
  before do
    @git_path = '/path/to/toplevel'
    @io_handle = ''
    IO.stub!(:popen).with("git rev-parse --show-toplevel").and_return(@io_handle)
    @io_handle.stub!(:read).and_return(@git_path + "\n")
  end
  
  it 'should work without arguments' do
    lambda { git_changes_path }.should.not.raise(ArgumentError)
  end
  
  it 'should not allow arguments' do
    lambda { git_changes_path(:foo) }.should.raise(ArgumentError)
  end
  
  it 'should return the path to the .whiskey_disk_git_changes file in the git top-level path' do
    git_changes_path.should == File.join(@git_path, '.whiskey_disk_git_changes')
  end
  
  it 'should return the path to the .whiskey_disk_git_changes file in the current directory of the git top-level cannot be found' do
    @io_handle.stub!(:read).and_return('')
    git_changes_path.should == File.join(Dir.pwd, '.whiskey_disk_git_changes')    
  end
end

describe 'computing the path to the rsync changes file' do
  before do
    @rsync_path = '/path/to/toplevel'
    @io_handle = ''
    IO.stub!(:popen).with("git rev-parse --show-toplevel").and_return(@io_handle)
    @io_handle.stub!(:read).and_return(@rsync_path + "\n")
  end
  
  it 'should work without arguments' do
    lambda { rsync_changes_path }.should.not.raise(ArgumentError)
  end
  
  it 'should not allow arguments' do
    lambda { rsync_changes_path(:foo) }.should.raise(ArgumentError)
  end
  
  it 'should return the path to the .whiskey_disk_rsync_changes file in the git top-level path' do
    rsync_changes_path.should == File.join(@rsync_path, '.whiskey_disk_rsync_changes')
  end
  
  it 'should return the path to the .whiskey_disk_rsync_changes file in the current directory of the git top-level cannot be found' do
    @io_handle.stub!(:read).and_return('')
    rsync_changes_path.should == File.join(Dir.pwd, '.whiskey_disk_rsync_changes')    
  end
end