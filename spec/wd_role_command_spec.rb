require File.dirname(__FILE__) + '/spec_helper.rb'

def run_command
  eval File.read(File.join(File.dirname(__FILE__), *%w[.. bin wd_role]))
end

describe 'wd role command' do
  before do
    ENV['WD_ROLES'] = nil
  end
  
  describe 'when no command-line arguments are specified' do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = []
    end  
    
    it 'fails' do
      lambda { run_command }.should.raise(SystemExit)
    end
  end
  
  describe "when a role is specified on the command-line" do
    before do
      Object.send(:remove_const, :ARGV)
      ARGV = ['app']
    end  

    it 'fails when no WD_ROLES environment setting is present' do
      ENV['WD_ROLES'] = nil
      lambda { run_command }.should.raise(SystemExit)
    end
    
    it 'fails when an empty WD_ROLES environment setting is present' do
      ENV['WD_ROLES'] = ''
      lambda { run_command }.should.raise(SystemExit)
    end
    
    it 'fails when the WD_ROLES environment setting does not contain that role' do
      ENV['WD_ROLES'] = 'web:nonapp:db'
      lambda { run_command }.should.raise(SystemExit)
    end
    
    it 'succeeds when the WD_ROLES environment setting contains that role' do
      ENV['WD_ROLES'] = 'web:app:db'
      lambda { run_command }.should.not.raise
    end    
  end
end