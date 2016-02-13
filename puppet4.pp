# puppet apply puppet4.pp

$collection_version   = 'pc1'
$puppet_agent_version = undef # or, e.g. '1.3.5-1wily'

Exec {
  path => ['/bin', '/usr/bin', '/usr/local/bin'],
}

case $osfamily {
  'Debian': {
    $code_name                = $lsbdistcodename
    $enabler_package_name     = "puppetlabs-release-${collection_version}-${code_name}.deb"
    $enabler_package_url      = "https://apt.puppetlabs.com/${enabler_package_name}"
    $enabler_package_source   = "/tmp/${enabler_package_name}"
    $enabler_package_provider = 'dpkg'
    $update_command           = 'apt-get update -y'

    package { 'wget':
      ensure => installed,
    }

    exec { 'Get Puppet Collection Enabler Package':
      command => "wget ${enabler_package_url}",
      creates => $enabler_package_source,
      cwd     => '/tmp',
      before  => Package["puppetlabs-release-${collection_version}"],
      require => Package['wget'],
    }
  }
  default: { notice("Unsupported OS, please install manually.") }
}

package { "puppetlabs-release-${collection_version}":
  ensure   => installed,
  provider => $enabler_package_provider,
  source   => $enabler_package_source,
  notify   => Exec['Update Package Manager'],
}

exec { 'Update Package Manager':
  command     => $update_command,
  before      => Package['puppet-agent'],
}

package { 'puppet':
  ensure => absent,
  before => Package['puppet-agent'],
}

package { 'puppet-agent':
  ensure  => $puppet_agent_version ? {
    undef   => installed,
    default => $puppet_agent_version,
  }
}
