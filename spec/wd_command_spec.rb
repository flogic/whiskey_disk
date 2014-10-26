require_relative('spec_helper.rb')
require 'rake'

def run_command
  cmd_path = File.expand_path(File.join(File.dirname(__FILE__), *%w[.. bin wd]))
  path = File.expand_path(File.dirname(cmd_path))
  file = File.read(cmd_path)

  Dir.chdir(path) do |path|
    eval(file)
  end
end

describe 'wd command' do
  before do
    @stderr, @stdout, $stderr, $stdout = $stderr, $stdout, StringIO.new, StringIO.new
    ENV['to'] = ENV['path'] = nil
  end

  after do
    @stderr, @stdout, $stderr, $stdout = $stderr, $stdout, @stderr, @stdout
  end
  
  describe 'when no command-line arguments are specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
    
    it 'does not run rake tasks' do
      Rake::Application.should.receive(:new).never
      lambda { run_command }
    end
  
    it 'exits' do
      lambda { run_command }.should.raise(SystemExit)
    end
    
    it 'exits with a failure status' do
      begin
        run_command
      rescue Exception => e
        e.success?.should == false
      end
    end
  end

  it 'outputs usage without a backtrace when --help is specified' do
    Object.send(:remove_const, :ARGV)
    ARGV = ['--help']
    lambda { run_command }.should.raise(SystemExit)
  end
  
  it 'outputs usage without a backtrace when garbage options are specified' do
    Object.send(:remove_const, :ARGV)
    ARGV = ['--slkjfsdflkj']
    lambda { run_command }.should.raise(SystemExit)
  end
  
  describe 'when --version argument is specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['--version']
    end
  
    # it 'outputs the version stored in the VERSION file' do
    #   version = File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'VERSION'))).chomp
    #   # TODO: capture version output
    #   lambda{ run_command }
    # end
  
    it 'exits' do
      lambda { run_command }.should.raise(SystemExit)
    end
  
    it 'exits successfully' do
      begin
        run_command
      rescue SystemExit => e
        e.success?.should == true
      end
    end
  end

  describe "when the 'setup' command is specified" do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['setup']
    end  

    describe 'and no target is specified' do    
      it 'does not run rake tasks' do
        Rake::Application.should.receive(:new).never
        lambda { run_command }
      end

      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end

    
    describe 'and a --to argument is specified' do
      before do
        ARGV.push '--to=foo'
        @rake = Rake::Task['deploy:setup']
        @rake.stub!(:invoke)
      end
      
      it 'does not fail' do
        lambda { run_command }.should.not.raise
      end
      
      it 'runs the deploy:setup rake task' do
        @rake.should.receive(:invoke)
        run_command
      end
      
      it 'makes the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end
      
      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --path or -p argument is specified' do
        it 'does not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end

        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
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

        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and no --only or -o argument is specified' do
        it 'does not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --debug argument is specified' do
        before do
          ARGV.push '--debug'
        end

        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end

        it 'makes the specified target available as a "debug" argument to the rake task' do
          run_command
          ENV['debug'].should == 'true'
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and a -d argument is specified' do
        before do
          ARGV.push '-d'
        end

        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end

        it 'makes the specified target available as a "debug" argument to the rake task' do
          run_command
          ENV['debug'].should == 'true'
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and no --debug or -d argument is specified' do
        it 'does not make a "debug" argument available to the rake task' do
          run_command
          ENV['debug'].should.be.nil
        end

        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
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

      it 'does not fail' do
        lambda { run_command }.should.not.raise
      end

      it 'runs the deploy:setup rake task' do
        @rake.should.receive(:invoke)
        run_command
      end

      it 'makes the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --path or -p argument is specified' do
        it 'does not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end

        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
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

        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and no --only or -o argument is specified' do
        it 'does not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
        end

        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end

        it 'does not fail if the rake task succeeds' do
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
      it 'does not run rake tasks' do
        Rake::Application.should.receive(:new).never
        lambda { run_command }
      end
  
      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end
    
    describe 'and a --to argument is specified' do
      before do
        ARGV.push '--to=foo'
        @rake = Rake::Task['deploy:now']
        @rake.stub!(:invoke)
      end
      
      it 'does not fail' do
        lambda { run_command }.should.not.raise
      end
      
      it 'runs the deploy:now rake task' do
        @rake.should.receive(:invoke)
        run_command
      end
      
      it 'makes the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end
    
      describe 'and a --check argument is specified' do
        before do
          ARGV.push '--check'
          @rake = Rake::Task['deploy:now']
          @rake.stub!(:invoke)
        end
           
        it 'does not fail' do
          lambda { run_command }.should.not.raise
        end
      
        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end
      
        it 'makes the specified target available as a "check" argument to the rake task' do
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
           
        it 'does not fail' do
          lambda { run_command }.should.not.raise
        end
      
        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end
      
        it 'makes the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and no --check or -c argument is specified' do        
        it 'does not make a "check" argument available to the rake task' do          
          run_command
          ENV['check'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --path or -p argument is specified' do        
        it 'does not make a "path" argument available to the rake task' do
          run_command
          ENV['path'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end
        
        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
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
        
        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --only or -o argument is specified' do
        it 'does not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
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

      it 'does not fail' do
        lambda { run_command }.should.not.raise
      end

      it 'runs the deploy:now rake task' do
        @rake.should.receive(:invoke)
        run_command
      end

      it 'makes the specified target available as a "to" argument to the rake task' do
        run_command
        ENV['to'].should == 'foo'
      end
  
      describe 'and a --check argument is specified' do
        before do
          ARGV.push '--check'
          @rake = Rake::Task['deploy:now']
          @rake.stub!(:invoke)
        end
         
        it 'does not fail' do
          lambda { run_command }.should.not.raise
        end
    
        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end
    
        it 'makes the specified target available as a "check" argument to the rake task' do
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
         
        it 'does not fail' do
          lambda { run_command }.should.not.raise
        end
    
        it 'runs the deploy:now rake task' do
          @rake.should.receive(:invoke)
          run_command
        end
    
        it 'makes the specified target available as a "check" argument to the rake task' do
          run_command
          ENV['check'].should == 'true'
        end
      end

      describe 'and no --check or -c argument is specified' do        
        it 'does not make a "check" argument available to the rake task' do          
          run_command
          ENV['check'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end

      describe 'and a --path argument is specified' do
        before do
          ARGV.push '--path=/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and a -p argument is specified' do
        before do
          ARGV.push '-p'
          ARGV.push '/path/to/foo'
        end
        
        it 'makes the specified path available as a "path" argument to the rake task' do
          run_command
          ENV['path'].should == '/path/to/foo'
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --path or -p argument is specified' do
        it 'does not make a "path" argument available to the rake task' do
          ENV['path'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
          
      describe 'and a --only argument is specified' do
        before do
          @domain = 'smeghost'
          ARGV.push "--only=#{@domain}"
        end
        
        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
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
        
        it 'makes the specified domain available as an "only" argument to the rake task' do
          run_command
          ENV['only'].should == @domain
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
          @rake.stub!(:invoke).and_return(true)
          lambda { run_command }.should.not.raise
        end
      end
      
      describe 'and no --only or -o argument is specified' do
        it 'does not make an "only" argument available to the rake task' do
          run_command
          ENV['only'].should.be.nil
        end
      
        it 'fails if the rake task fails' do
          @rake.stub!(:invoke).and_raise(RuntimeError)
          lambda { run_command }.should.raise
        end
      
        it 'does not fail if the rake task succeeds' do
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
    
    describe 'when no target is specified' do
      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end

    describe 'when a target is specified' do
      before do
        ARGV.push('--to=foo')        
      end
      
      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end
  end
  
  describe 'and an unknown command is specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['frazzlebazzle']
    end
    
    describe 'when no target is specified' do
      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end

    describe 'when a target is specified' do
      before do
        ARGV.push('--to=foo')        
      end
      
      it 'exits when a target is specified' do
        lambda { run_command }.should.raise(SystemExit)
      end

      it 'exits with a failing status when a target is specified' do
        begin
          run_command
        rescue SystemExit => e
          e.success?.should == false
        end
      end
    end
  end
end
