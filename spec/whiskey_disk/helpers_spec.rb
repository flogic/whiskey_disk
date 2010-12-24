require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'whiskey_disk', 'helpers'))

describe '#role?' do
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

