require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

def do_install
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. install.rb ]))
end

describe 'the plugin install.rb script' do
  before do
    self.stub!(:puts).and_return(true)
  end

  it 'displays the content of the plugin README file' do
    self.stub!(:readme_contents).and_return('README CONTENTS')
    self.should.receive(:puts).with('README CONTENTS')
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
      File.stub!(:join).and_return('/path/to/README')
      IO.should.receive(:read).with('/path/to/README')
      readme_contents
    end

    it 'returns the contents of the plugin README file' do
      do_install
      File.stub!(:join).and_return('/path/to/README')
      IO.stub!(:read).with('/path/to/README').and_return('README CONTENTS')
      readme_contents.should == 'README CONTENTS'
    end
  end
end