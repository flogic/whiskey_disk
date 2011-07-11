require 'rubygems'
require 'bacon'
require 'facon'
require 'fileutils'
require 'tempfile'
require 'erb'
require 'tmpdir'

if ENV['DEBUG'] and ENV['DEBUG'] != ''
  STDERR.puts "Enabling debugger for spec runs..."
  require 'rubygems'
  require 'ruby-debug'
  Debugger.start
end

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

# create a file at the specified path
def make(path)
  FileUtils.mkdir_p(File.dirname(path))
  FileUtils.touch(path)
end

def build_temp_dir
  return Dir.mktmpdir(nil, '/private/tmp') if File.exists?('/private/tmp')
  Dir.mktmpdir
end

def write_config_file(data)
  File.open(@config_file, 'w') { |f| f.puts YAML.dump(data) }
end

# local target directory, integration spec workspace
def deployment_root
  File.expand_path(File.join(File.dirname(__FILE__), '..', 'scenarios', 'setup', 'vagrant', 'deployed', 'target'))
end

# allow defining an integration spec block
def integration_spec(&block)
  yield if ENV['INTEGRATION'] and ENV['INTEGRATION'] != ''
end

# reset the deployment directory for integration specs
def setup_deployment_area
  FileUtils.rm_rf(deployment_root)
  File.umask(0)
  Dir.mkdir(deployment_root, 0777)
  Dir.mkdir(deployed_file('log'), 0777)
end

# run a wd setup using the provided arguments string
def run_setup(arguments, debugging = true)
  wd_path  = File.join(File.dirname(__FILE__), '..', 'bin', 'wd')
  lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
  debug = debugging ? '--debug' : ''
  system("/usr/bin/env ruby -I #{lib_path} -r whiskey_disk -rubygems #{wd_path} setup #{debug} #{arguments} > #{integration_log} 2> #{integration_log}")
end

def integration_log
  deployed_file('log/out.txt')
end

# run a wd setup using the provided arguments string
def run_deploy(arguments, debugging = true)
  wd_path  = File.join(File.dirname(__FILE__), '..', 'bin', 'wd')
  lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
  debug = debugging ? '--debug' : ''
  status = system("/usr/bin/env ruby -I #{lib_path} -r whiskey_disk -rubygems #{wd_path} deploy #{debug} #{arguments} > #{integration_log} 2> #{integration_log}")
  status
end

# build the correct local path to the deployment configuration for a given scenario
def scenario_config(path)
  return erb_scenario_config(path) if path =~ /\.erb$/
  scenario_config_path(path)
end

def scenario_config_path(path)
  File.join(File.dirname(__FILE__), '..', 'scenarios', path)
end

def erb_scenario_config(path)
  data = File.read(scenario_config_path(path))
  converted = erb_eval(data)
  write_tempfile(converted)
end

def erb_eval(data)
  ERB.new(data).result
end

def write_tempfile(data)
  tmp_file = Tempfile.new('whiskey_disk_integration_spec_scenario')
  tmp_file.puts(data)
  tmp_file.close
  tmp_file.path
end

# clone a git repository locally (as if a "wd setup" had been deployed)
def checkout_repo(repo_name, branch = nil)
  repo_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'scenarios', 'git_repositories', "#{repo_name}.git"))
  system("cd #{deployment_root} && git clone #{repo_path} >/dev/null 2>/dev/null && cd #{repo_name} && git remote set-url origin #{remote_url(repo_name)}")
  checkout_branch(repo_name, branch)
end

def remote_url(repo)
  "git://wd-git.example.com/#{repo}.git"
end

def checkout_branch(repo_name, branch = nil)
  return unless branch
  system("cd #{deployment_root}/#{repo_name} && git checkout #{branch} >/dev/null 2>/dev/null")
end

def jump_to_initial_commit(path)
  system(%Q(cd #{File.join(deployment_root, path)} && git reset --hard `git log --oneline | tail -1 | awk '{print $1}'` >/dev/null 2>/dev/null))
end

def run_log
  File.readlines(integration_log)
end

def deployed_file(path)
  File.join(deployment_root, path)
end

def dump_log
  STDERR.puts("\n\n\n" + File.read(integration_log) + "\n\n\n")
end

def current_branch(path)
  `cd #{deployed_file(path)} && git branch`.split("\n").grep(/^\*/).first.sub(/^\* /, '')
end
