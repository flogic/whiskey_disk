require 'rubygems'
require 'bacon'
require 'facon'
require 'fileutils'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

# local target directory, integration spec workspace
def deployment_root
  '/tmp/wd-integration-target/'
end

# allow defining an integration spec block
def integration_spec(&block)
  yield if ENV['INTEGRATION'] and ENV['INTEGRATION'] != ''
end

# reset the deployment directory for integration specs
def setup_deployment_area
  FileUtils.rm_rf(deployment_root)
  Dir.mkdir(deployment_root, 0777)
  Dir.mkdir(File.join(deployment_root, 'log'), 0777)
end

# run a wd setup using the provided arguments string
def run_setup(arguments)
  wd_path  = File.join(File.dirname(__FILE__), '..', 'bin', 'wd')
  lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
  system("/usr/bin/env ruby -I #{lib_path} -r whiskey_disk -rubygems #{wd_path} setup #{arguments} > #{integration_log} 2> #{integration_log}")
end

def integration_log
  deployed_file('log/out.txt')
end

# run a wd setup using the provided arguments string
def run_deploy(arguments)
  wd_path  = File.join(File.dirname(__FILE__), '..', 'bin', 'wd')
  lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
  status = system("/usr/bin/env ruby -I #{lib_path} -r whiskey_disk -rubygems #{wd_path} deploy #{arguments} > #{integration_log} 2> #{integration_log}")
  status
end

# build the correct local path to the deployment configuration for a given scenario
def scenario_config(path)
  File.join(File.dirname(__FILE__), '..', 'scenarios', path)
end

# clone a git repository locally (as if a "wd setup" had been deployed)
def checkout_repo(repo_name, name = '')
  repo_path = File.join(File.dirname(__FILE__), '..', 'scenarios', 'git_repositories', "#{repo_name}.git")
  system("cd #{deployment_root} && git clone #{repo_path} #{name} >/dev/null 2>/dev/null")
end

def run_log
  File.readlines(integration_log)
end

def deployed_file(path)
  File.join(deployment_root, path)
end