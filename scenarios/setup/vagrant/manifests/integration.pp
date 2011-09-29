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
  host_aliases => 'wd-git.example.com',
  ip           => '10.0.2.2',
}

package {'git-core':
  ensure       => 'latest'
}

package {'rake':
  ensure       => 'latest'
}
