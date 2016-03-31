# == Class: graphite::config
#
# This class configures graphite/carbon/whisper and SHOULD NOT
# be called directly.
#
# === Parameters
#
# None.
#
class graphite::config inherits graphite::params {
  Exec {
    path => '/bin:/usr/bin:/usr/sbin' }

  # for full functionality we need this packages:
  # mandatory: python-cairo, python-django, python-twisted,
  #            python-django-tagging, python-simplejson
  # optional:  python-ldap, python-memcache, memcached, python-sqlite

  if $::service_provider == 'systemd' or ($::service_provider == 'debian' and $::operatingsystemmajrelease =~ /8|15\.10/) {
    $initscript_notify = [Exec['graphite-reload-systemd'],]

    exec { 'graphite-reload-systemd':
      command     => 'systemctl daemon-reload',
      path        => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin'],
      refreshonly => true,
    }
  } else {
    $initscript_notify = []
  }

  if $::graphite::gr_pip_install {
    $local_settings_py_file = "${::graphite::gr_graphiteweb_install_lib_dir}/local_settings.py"
    $syncdb_require         = File[$local_settings_py_file]
  } else {
    # using custom directories.
    file { "${::graphite::gr_graphiteweb_conf_dir}/manage.py":
      ensure => link,
      target => "${::graphite::params::libpath}/graphite/manage.py"
    }
    $local_settings_py_file = "${::graphite::gr_graphiteweb_conf_dir}/local_settings.py"
    $syncdb_require         = [
      File[$local_settings_py_file],
      File["${::graphite::gr_graphiteweb_conf_dir}/manage.py"]]
  }

  # we need an web server with python support
  # apache with mod_wsgi or nginx with gunicorn
  case $graphite::gr_web_server {
    'apache'   : {
      $gr_web_user_REAL  = pick($::graphite::gr_web_user, $::graphite::params::apache_web_user)
      $gr_web_group_REAL = pick($::graphite::gr_web_group, $::graphite::params::apache_web_group)
      include graphite::config_apache
      $web_server_package_require = [Package[$::graphite::params::apache_pkg]]
    }

    'nginx'    : {
      # Configure gunicorn and nginx.
      $gr_web_user_REAL  = pick($::graphite::gr_web_user, $::graphite::params::nginx_web_user)
      $gr_web_group_REAL = pick($::graphite::gr_web_group, $::graphite::params::nginx_web_group)
      include graphite::config_gunicorn
      include graphite::config_nginx
      $web_server_package_require = [Package['nginx']]
    }

    'wsgionly' : {
      # Configure gunicorn only without nginx.
      if !$::graphite::gr_web_user or !$::graphite::gr_web_group {
        fail('having $gr_web_server => \'wsgionly\' requires use of $gr_web_user and $gr_web_group')
      }
      $gr_web_user_REAL  = pick($::graphite::gr_web_user)
      $gr_web_group_REAL = pick($::graphite::gr_web_group)
      include graphite::config_gunicorn
      $web_server_package_require = undef
    }

    'none'     : {
      # Don't configure apache, gunicorn or nginx. Leave all webserver configuration to something external.
      if !$::graphite::gr_web_user or !$::graphite::gr_web_group {
        fail('having $gr_web_server => \'wsgionly\' requires use of $gr_web_user and $gr_web_group')
      }
      $gr_web_user_REAL           = pick($::graphite::gr_web_user)
      $gr_web_group_REAL          = pick($::graphite::gr_web_group)
      $web_server_package_require = undef
    }

    default    : {
      fail('The only supported web servers are \'apache\', \'nginx\', \'wsgionly\' and \'none\'')
    }
  }

  $carbon_conf_file               = "${::graphite::gr_carbon_conf_dir}/carbon.conf"
  $graphite_web_managepy_location = $::graphite::gr_pip_install ? {
    false   => $::graphite::gr_graphiteweb_conf_dir,
    default => $::graphite::gr_graphiteweb_install_lib_dir,
  }

  # first init of user db for graphite
  exec { 'Initial django db creation':
    command     => 'python manage.py syncdb --noinput',
    cwd         => $graphite_web_managepy_location,
    refreshonly => true,
    require     => $syncdb_require,
    subscribe   => Class['graphite::install'],
  }

  # change access permissions for web server

  file { [
    $::graphite::gr_storage_dir,
    $::graphite::gr_rrd_dir,
    $::graphite::gr_whitelists_dir,
    $::graphite::gr_graphiteweb_log_dir,
    $::graphite::gr_pid_dir,
    "${::graphite::gr_base_dir}/bin"]:
    ensure    => directory,
    group     => $gr_web_group_REAL,
    mode      => '0755',
    owner     => $gr_web_user_REAL,
    subscribe => Exec['Initial django db creation'],
  }

  # change access permissions for carbon-cache to align with gr_user
  # (if different from web_user)

  if $::graphite::gr_user != '' {
    $carbon_user  = $::graphite::gr_user
    $carbon_group = $::graphite::gr_group
  } else {
    $carbon_user  = $gr_web_user_REAL
    $carbon_group = $gr_web_group_REAL
  }

  file {
    $::graphite::gr_local_data_dir:
      ensure => directory,
      group  => $carbon_group,
      mode   => '0755',
      owner  => $carbon_user,
      path   => $::graphite::gr_local_data_dir;

    $::graphite::gr_carbon_log_dir:
      ensure => directory,
      group  => $carbon_group,
      mode   => '0755',
      owner  => $carbon_user;
  }

  # Lets ensure graphite.db owner is the same as gr_web_user_REAL
  file { "${::graphite::gr_storage_dir}/graphite.db":
    ensure => file,
    group  => $gr_web_group_REAL,
    mode   => '0644',
    owner  => $gr_web_user_REAL;
  }

  # Deploy configfiles
  file {
    $local_settings_py_file:
      ensure  => file,
      content => template('graphite/opt/graphite/webapp/graphite/local_settings.py.erb'),
      group   => $gr_web_group_REAL,
      mode    => '0644',
      owner   => $gr_web_user_REAL,
      require => $web_server_package_require;

    "${::graphite::gr_graphiteweb_conf_dir}/graphite_wsgi.py":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/graphite.wsgi.erb'),
      group   => $gr_web_group_REAL,
      mode    => '0644',
      owner   => $gr_web_user_REAL,
      require => $web_server_package_require;

    "${::graphite::gr_graphiteweb_install_lib_dir}/graphite_wsgi.py":
      ensure  => link,
      target  => "${::graphite::gr_graphiteweb_conf_dir}/graphite_wsgi.py",
      require => File["${::graphite::gr_graphiteweb_conf_dir}/graphite_wsgi.py"];
  }

  if $::graphite::gr_remote_user_header_name {
    file { "${::graphite::gr_graphiteweb_install_lib_dir}/custom_auth.py":
      ensure  => file,
      content => template('graphite/opt/graphite/webapp/graphite/custom_auth.py.erb'),
      group   => $gr_web_group_REAL,
      mode    => '0644',
      owner   => $gr_web_user_REAL,
      require => $web_server_package_require,
    }
  }

  # configure carbon engines
  if $::graphite::gr_enable_carbon_cache {
    $service_cache = Service['carbon-cache']
  } else {
    $service_cache = undef
  }

  if $::graphite::gr_enable_carbon_relay {
    $service_relay = Service['carbon-relay']
  } else {
    $service_relay = undef
  }

  if $::graphite::gr_enable_carbon_aggregator {
    $service_aggregator = Service['carbon-aggregator']
  } else {
    $service_aggregator = undef
  }

  $notify_services = delete_undef_values([
    $service_cache,
    $service_relay,
    $service_aggregator])

  if $::graphite::gr_enable_carbon_relay {
    file { "${::graphite::gr_carbon_conf_dir}/relay-rules.conf":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/relay-rules.conf.erb'),
      mode    => '0644',
      notify  => $notify_services,
    }
  }

  if $::graphite::gr_enable_carbon_aggregator {
    file { "${::graphite::gr_carbon_conf_dir}/aggregation-rules.conf":
      ensure  => file,
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/aggregation-rules.conf.erb'),
      notify  => $notify_services;
    }
  }

  file {
    "${::graphite::gr_carbon_conf_dir}/storage-schemas.conf":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/storage-schemas.conf.erb'),
      mode    => '0644',
      notify  => $notify_services;

    $carbon_conf_file:
      ensure  => file,
      content => template('graphite/opt/graphite/conf/carbon.conf.erb'),
      mode    => '0644',
      notify  => $notify_services;

    "${::graphite::gr_carbon_conf_dir}/storage-aggregation.conf":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/storage-aggregation.conf.erb'),
      mode    => '0644';

    "${::graphite::gr_carbon_conf_dir}/whitelist.conf":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/whitelist.conf.erb'),
      mode    => '0644';

    "${::graphite::gr_carbon_conf_dir}/blacklist.conf":
      ensure  => file,
      content => template('graphite/opt/graphite/conf/blacklist.conf.erb'),
      mode    => '0644';
  }

  # configure logrotate script for carbon
  file { "${::graphite::gr_base_dir}/bin/carbon-logrotate.sh":
    ensure  => file,
    mode    => '0544',
    content => template('graphite/opt/graphite/bin/carbon-logrotate.sh.erb'),
  }

  cron { 'Rotate carbon logs':
    command => "${::graphite::gr_base_dir}/bin/carbon-logrotate.sh",
    hour    => 1,
    minute  => 15,
    require => File["${::graphite::gr_base_dir}/bin/carbon-logrotate.sh"],
    user    => root,
  }

  # startup carbon engine

  if $graphite::gr_enable_carbon_cache {
    service { 'carbon-cache':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      provider   => $::graphite::service_provider,
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
      provider   => $::graphite::service_provider,
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
      provider   => $::graphite::service_provider,
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
