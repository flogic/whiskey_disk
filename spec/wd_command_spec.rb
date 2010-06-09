require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rake'

def run_command
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin wd]))
end

describe 'wd command' do
  before do
    @usage = 'USAGE MESSAGE'
    self.stub!(:usage).and_return(@usage)
    self.stub!(:exit)
    self.stub!(:puts)
  end

  describe 'when no command-line arguments are specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  

    it 'should display a usage message' do
      self.should.receive(:puts).with(@usage)
      run_command
    end
    
    it 'should not run rake tasks' do
      Rake::Application.should.receive(:new).never
      run_command
    end
  
    it 'should exit successfully' do
      self.should.receive(:exit).with(0)
      run_command
    end
  end
  
  describe "when -a is specified on the command-line" do
    
  end
end