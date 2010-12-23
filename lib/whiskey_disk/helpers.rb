
# is the current deployment domain in the specified role?
def role?(role)
  return false unless ENV['WD_ROLES'] and ENV['WD_ROLES'] != ''
  ENV['WD_ROLES'].split(':').include?(role.to_s)
end