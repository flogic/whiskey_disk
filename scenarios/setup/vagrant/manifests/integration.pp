file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine! Managed by Puppet.\n"
}

file { '/opt/deploy/target':
  ensure => directory, 
  owner => 'vagrant',
  group => 'vagrant', 
  mode => '775'
}

host {'host':
  ensure       => 'present',
  ip           => '10.0.2.2',
}

# TODO: we need to be able to get the *development* version of the library built and installed on the integration host
#
# package { 'whiskey_disk':
#   name => 'whiskey_disk',
#   ensure => installed,
#   provider => 'gem',
# }

