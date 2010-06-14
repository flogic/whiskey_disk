require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rake'

def run_command
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin wd]))
end

describe 'wd command' do
  describe 'when no command-line arguments are specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
    
    it 'should not run rake tasks' do
      Rake::Application.should.receive(:new).never
      lambda { run_command }
    end
  
    it 'should fail' do
      lambda { run_command }.should.raise
    end
  end
  
  describe "when the 'setup' command is specified" do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['setup']
    end  

    describe 'and no target is specified' do    
      it 'should not run rake tasks' do
        Rake::Application.should.receive(:new).never
        lambda { run_command }
      end
  
      it 'should fail' do
        lambda { run_command }.should.raise
      end
    end
    
    describe 'and a --to argument is specified' do
      before do
        ARGV.push '--to=foo'
        @rake = Rake::Task['deploy:setup']
        @rake.stub!(:invoke)
      end
      
      it 'should not fail' do
        lambda { run_command }.should.not.raise
      end
      
      it 'should run the deploy:setup rake task' do
        @rake.should.receive(:invoke)
        run_command
      end
      
      it 'should make the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end
      
      it 'should fail if the rake task fails' do
        @rake.stub!(:invoke).and_raise(RuntimeError)
        lambda { run_command }.should.raise
      end
      
      it 'should not fail if the rake task succeeds' do
        @rake.stub!(:invoke).and_return(true)
        lambda { run_command }.should.not.raise
      end
    end

    describe 'and a -t argument is specified' do
      before do
        ARGV.push '-t'
        ARGV.push 'foo'
        @rake = Rake::Task['deploy:setup']
        @rake.stub!(:invoke)
      end

      it 'should not fail' do
        lambda { run_command }.should.not.raise
      end

      it 'should run the deploy:setup rake task' do
        @rake.should.receive(:invoke)
        run_command
      end

      it 'should make the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end

      it 'should fail if the rake task fails' do
        @rake.stub!(:invoke).and_raise(RuntimeError)
        lambda { run_command }.should.raise
      end

      it 'should not fail if the rake task succeeds' do
        @rake.stub!(:invoke).and_return(true)
        lambda { run_command }.should.not.raise
      end
    end
  end
  
  describe "when the 'deploy' command is specified" do
    describe 'but no target is specified' do
      before do
        Object.send(:remove_const, :ARGV)
        ARGV = ['deploy']
      end  

      it 'should not run rake tasks' do
        Rake::Application.should.receive(:new).never
        lambda { run_command }
      end
  
      it 'should fail' do
        lambda { run_command }.should.raise
      end
    end
    
    describe 'and a --to argument is specified' do
      before do
        ARGV.push '--to=foo'
        @rake = Rake::Task['deploy:now']
        @rake.stub!(:invoke)
      end
      
      it 'should not fail' do
        lambda { run_command }.should.not.raise
      end
      
      it 'should run the deploy:now rake task' do
        @rake.should.receive(:invoke)
        run_command
      end
      
      it 'should make the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end
      
      it 'should fail if the rake task fails' do
        @rake.stub!(:invoke).and_raise(RuntimeError)
        lambda { run_command }.should.raise
      end
      
      it 'should not fail if the rake task succeeds' do
        @rake.stub!(:invoke).and_return(true)
        lambda { run_command }.should.not.raise
      end
    end

    describe 'and a -t argument is specified' do
      before do
        ARGV.push '-t'
        ARGV.push 'foo'
        @rake = Rake::Task['deploy:now']
        @rake.stub!(:invoke)
      end

      it 'should not fail' do
        lambda { run_command }.should.not.raise
      end

      it 'should run the deploy:now rake task' do
        @rake.should.receive(:invoke)
        run_command
      end

      it 'should make the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end

      it 'should fail if the rake task fails' do
        @rake.stub!(:invoke).and_raise(RuntimeError)
        lambda { run_command }.should.raise
      end

      it 'should not fail if the rake task succeeds' do
        @rake.stub!(:invoke).and_return(true)
        lambda { run_command }.should.not.raise
      end
    end
  end
  
  describe 'and more than one command is specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['frazzlebazzle', 'shizzlebizzle']
    end
    
    it 'should fail if no target is specified' do
      lambda { run_command }.should.raise
    end
    
    it 'should fail even if a target is specified' do
      ARGV.push('--to=foo')
      lambda { run_command }.should.raise
    end
  end
  
  describe 'and an unknown command is specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['frazzlebazzle']
    end
    
    it 'should fail when no target is specified' do
      lambda { run_command }.should.raise
    end
    
    it 'should fail when a target is specified' do
      ARGV.push('--to=foo')
      lambda { run_command }.should.raise
    end
  end
end