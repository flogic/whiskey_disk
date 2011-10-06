require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

def do_install
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. install.rb ]))
end

describe 'the plugin install.rb script' do
  before do
    self.stubs(:puts).returns(true)
  end
  
  it 'displays the content of the plugin README file' do
    self.stubs(:readme_contents).returns('README CONTENTS')
    self.expects(:puts).with('README CONTENTS')
    do_install
  end
  
  describe 'readme_contents' do
    it 'works without arguments' do
      do_install
      lambda { readme_contents }.should.not.raise(ArgumentError)
    end
    
    it 'accepts no arguments' do
      do_install
      lambda { readme_contents(:foo) }.should.raise(ArgumentError)
    end
    
    it 'reads the plugin README file' do
      do_install
      File.stubs(:join).returns('/path/to/README')
      IO.expects(:read).with('/path/to/README')
      readme_contents
    end
    
    it 'returns the contents of the plugin README file' do
      do_install
      File.stubs(:join).returns('/path/to/README')
      IO.stubs(:read).with('/path/to/README').returns('README CONTENTS')
      readme_contents.should == 'README CONTENTS'
    end
  end
end