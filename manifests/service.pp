# == Class: graphite::service
#
# This class enable and run graphite/carbon/whisper services and SHOULD NOT
# be called directly.
#
# === Parameters
#
# None.
#
class graphite::service inherits graphite::params {

  if ($::osfamily == 'RedHat' and $::operatingsystemrelease =~ /^7\.\d+/) or (
  $::graphite::params::service_provider == 'debian' and $::operatingsystemmajrelease =~ /8|15\.10/) {
    $initscript_notify = [Exec['graphite-reload-systemd'],]

    exec { 'graphite-reload-systemd':
      command     => 'systemctl daemon-reload',
      path        => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      refreshonly => true,
    }
  } else {
    $initscript_notify = []
  }

  $carbon_conf_file = "${::graphite::carbon_conf_dir_REAL}/carbon.conf"

  # startup carbon engine

  if $::graphite::gr_enable_carbon_cache {
    service { 'carbon-cache':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      provider   => $::graphite::params::service_provider,
      require    => File['/etc/init.d/carbon-cache'],
    }
  
    file { '/etc/init.d/carbon-cache':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-cache.erb"),
      mode    => '0750',
      require => File[$carbon_conf_file],
      notify  => $initscript_notify,
    }
  }

  if $graphite::gr_enable_carbon_relay {
    service { 'carbon-relay':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      provider   => $::graphite::params::service_provider,
      require    => File['/etc/init.d/carbon-relay'],
    }

    file { '/etc/init.d/carbon-relay':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-relay.erb"),
      mode    => '0750',
      require => File[$carbon_conf_file],
      notify  => $initscript_notify,
    }
  }

  if $graphite::gr_enable_carbon_aggregator {
    service { 'carbon-aggregator':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      provider   => $::graphite::params::service_provider,
      require    => File['/etc/init.d/carbon-aggregator'],
    }

    file { '/etc/init.d/carbon-aggregator':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-aggregator.erb"),
      mode    => '0750',
      require => File[$carbon_conf_file],
      notify  => $initscript_notify,
    }
  }
}
