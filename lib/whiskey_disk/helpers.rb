
# is the current deployment domain in the specified role?
def role?(role)
  return false unless ENV['WD_ROLES'] and ENV['WD_ROLES'] != ''
  ENV['WD_ROLES'].split(':').include?(role.to_s)
end

# does the current deployment have any role definitions?
def no_roles?
  ENV['WD_ROLES'] == ''
end

# look for a given role, or lack of all roles
def nothing_or_role?(role)
  no_roles? || role?(role)
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

def rsync_changes
  changes = read_rsync_changes_file.split("\n")
  changes.map {|c| c.sub(/^[^ ]* [^ ]* [^ ]* /, '') }.
          grep(/^[^ ]{9,} /).map {|c| c.sub(/^[^ ]{9,} /, '') }.
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
