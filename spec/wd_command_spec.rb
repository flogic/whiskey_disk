require File.dirname(__FILE__) + '/spec_helper.rb'
require 'rake'

def run_command
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin wd]))
end

describe 'wd command' do
  before do
    ENV['to'] = ENV['path'] = nil
  end
  
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

  it 'should output usage without a backtrace when --help is specified' do
    Object.send(:remove_const, :ARGV)
    ARGV = ['--help']
    self.stub!(:abort).and_raise(SystemExit)  # primarily to drop extraneous output
    lambda { run_command }.should.raise(SystemExit)
  end
  
  it 'should output usage without a backtrace when garbage options are specified' do
    Object.send(:remove_const, :ARGV)
    ARGV = ['--slkjfsdflkj']
    self.stub!(:abort).and_raise(SystemExit)  # primarily to drop extraneous output
    lambda { run_command }.should.raise(SystemExit)
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
      
      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and no --path or -p argument is specified' do
        it 'should not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
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

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end

        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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

      describe 'and a -o argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push '-o'
          ARGV.push @domain
        end

        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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

      describe 'and no --only or -o argument is specified' do
        it 'should not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
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

      describe 'and a --debug argument is specified' do
        before do
          ARGV.push '--debug'
        end

        it 'should run the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end

        it 'should make the specified target available as a "debug" argument to the rake task' do
          run_command
          ENV['debug'].should == 'true'
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
      
      describe 'and a -d argument is specified' do
        before do
          ARGV.push '-d'
        end

        it 'should run the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end

        it 'should make the specified target available as a "debug" argument to the rake task' do
          run_command
          ENV['debug'].should == 'true'
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

      describe 'and no --debug or -d argument is specified' do
        it 'should not make a "debug" argument available to the rake task' do
          run_command
          ENV['debug'].should.be.nil
        end

        it 'should run the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
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

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and no --path or -p argument is specified' do
        it 'should not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
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

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end

        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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

      describe 'and a -o argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push '-o'
          ARGV.push @domain
        end

        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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

      describe 'and no --only or -o argument is specified' do
        it 'should not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
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
  end
  
  describe "when the 'deploy' command is specified" do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['deploy']
    end  

    describe 'but no target is specified' do
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
    
      describe 'and a --check argument is specified' do
        before do
          ARGV.push '--check'
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
      
        it 'should make the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and a -c argument is specified' do
        before do
          ARGV.push '-c'
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
      
        it 'should make the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and no --check or -c argument is specified' do        
        it 'should not make a "check" argument available to the rake task' do          
          run_command
          ENV['check'].should.be.nil
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

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and no --path or -p argument is specified' do        
        it 'should not make a "path" argument available to the rake task' do
          run_command
          ENV['path'].should.be.nil
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

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end
        
        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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
      
      describe 'and a -o argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push '-o'
          ARGV.push @domain
        end
        
        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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
      
      describe 'and no --only or -o argument is specified' do
        it 'should not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
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
  
      describe 'and a --check argument is specified' do
        before do
          ARGV.push '--check'
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
    
        it 'should make the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and a -c argument is specified' do
        before do
          ARGV.push '-c'
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
    
        it 'should make the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and no --check or -c argument is specified' do        
        it 'should not make a "check" argument available to the rake task' do          
          run_command
          ENV['check'].should.be.nil
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

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'should make the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
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
      
      describe 'and no --path or -p argument is specified' do
        it 'should not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
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
          
      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end
        
        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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
      
      describe 'and a -o argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push '-o'
          ARGV.push @domain
        end
        
        it 'should make the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
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
      
      describe 'and no --only or -o argument is specified' do
        it 'should not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
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
