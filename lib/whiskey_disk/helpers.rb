
# is the current deployment domain in the specified role?
def role?(role)
  return false unless ENV['WD_ROLES'] and ENV['WD_ROLES'] != ''
  ENV['WD_ROLES'].split(':').include?(role.to_s)
end

# have files of interest changed on this deployment?
def changed?(path)
  return true unless gc = git_changes
  cleaned = Regexp.escape(path.sub(%r{/+$}, ''))
  [ gc, rsync_changes ].flatten.compact.any? { |p| p =~ %r<^#{cleaned}(?:$|/)> }
end

# list of changed paths, according to git
def git_changes
  changes = read_git_changes_file.split("\n").uniq
rescue Exception
  nil
end

# a helpful accessor to options set in git config
def git_config(key)
  git = Git.open('.').config
  git["deploy.#{key}"].strip if git.keys.include?("deploy.#{key}")
end

# this provides a helpful accessor to the previous sha used in the deployment
def last_deploy_sha
  git_config("previous-sha")
end

def current_branch
  git_config("branch")
end

def last_commit
  git_config('previous-commit')
end

# FIXME: should these be protected, or should they be accessible to deploy /
# rake authors?
def rsync_changes
  changes = read_rsync_changes_file.split("\n")
  changes.map {|c| c.sub(/^[^ ]* [^ ]* [^ ]* /, '') }.
          grep(/^[^ ]{9} /).map {|c| c.sub(/^[^ ]{9} /, '') }.
          map {|s| s.sub(%r{/$}, '') } - ['.']
rescue Exception
  nil
end

def read_git_changes_file
  File.read(git_changes_path)
end

def read_rsync_changes_file
  File.read(rsync_changes_path)
end

def changes_file_root
  path = IO.popen("git rev-parse --show-toplevel").read
  path == '' ? Dir.pwd : path.chomp
end

def git_changes_path
  File.join(changes_file_root, '.whiskey_disk_git_changes')
end

def rsync_changes_path
  File.join(changes_file_root, '.whiskey_disk_rsync_changes')
end
