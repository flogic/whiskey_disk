require File.expand_path(File.join(File.dirname(__FILE__), '..', 'whiskey_disk'))
require 'vlad'

def load_configuration
  WhiskeyDisk::Config.fetch.each_pair do |k,v|
    set k, v
  end
end

namespace :deploy do
  task :load_configuration do 
    load_configuration
  end  
  
  task :now do
  end
  
  task :setup do
  end
  
  task :refresh do
  end
end
