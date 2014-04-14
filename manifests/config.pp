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

  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  # for full functionality we need this packages:
  # mandatory: python-cairo, python-django, python-twisted,
  #            python-django-tagging, python-simplejson
  # optional:  python-ldap, python-memcache, memcached, python-sqlite

  # we need an web server with python support
  # apache with mod_wsgi or nginx with gunicorn
  case $graphite::gr_web_server {
    'apache': {
      include graphite::config_apache
      $web_server_package_require = [Package["${::graphite::params::web_server_pkg}"]]
    }
    'nginx': {
      # Configure gunicorn and nginx.
      include graphite::config_gunicorn
      include graphite::config_nginx
      $web_server_package_require = [Package["${::graphite::params::web_server_pkg}"]]
    }
    'wsgionly': {
      # Configure gunicorn only without nginx.
      include graphite::config_gunicorn
      $web_server_package_require = undef
    }
    'none': {
      # Don't configure apache, gunicorn or nginx. Leave all webserver configuration to something external.
      $web_server_package_require = undef
    }
    default: {
      fail('The only supported web servers are \'apache\', \'nginx\', \'wsgionly\' and \'none\'')
    }
  }

  # first init of user db for graphite

  exec { 'Initial django db creation':
    command     => 'python manage.py syncdb --noinput',
    cwd         => '/opt/graphite/webapp/graphite',
    refreshonly => true,
    subscribe   => Class['graphite::install'],
    require     => File['/opt/graphite/webapp/graphite/local_settings.py'];
  }~>

  # change access permissions for web server

  exec { 'Chown graphite for web user':
    command     => "chown -R ${::graphite::params::web_user}:${::graphite::params::web_user} /opt/graphite/storage/",
    cwd         => '/opt/graphite/',
    refreshonly => true,
    require     => $web_server_package_require,
  }

  # change access permissions for carbon-cache to align with gr_user
  # (if different from web_user)

  if $::graphite::gr_user != '' and $::graphite::gr_user != $::graphite::params::web_user {
    file {
      '/opt/graphite/storage/whisper':
        ensure  => directory,
        owner   => $::graphite::gr_user,
        group   => $::graphite::gr_user,
        mode    => '0755',
        require => Exec['Chown graphite for web user'];
      '/opt/graphite/storage/log/carbon-cache':
        ensure  => directory,
        owner   => $::graphite::gr_user,
        group   => $::graphite::gr_user,
        mode    => '0755',
        require => Exec['Chown graphite for web user'];
    }
  }

  # Deploy configfiles

  file {
    '/opt/graphite/webapp/graphite/local_settings.py':
      ensure  => file,
      owner   => $::graphite::params::web_user,
      group   => $::graphite::params::web_user,
      mode    => '0644',
      content => template('graphite/opt/graphite/webapp/graphite/local_settings.py.erb'),
      require => $web_server_package_require;
    '/opt/graphite/conf/graphite.wsgi':
      ensure  => file,
      owner   => $::graphite::params::web_user,
      group   => $::graphite::params::web_user,
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/graphite.wsgi.erb'),
      require => $web_server_package_require;
  }

  if $::graphite::gr_remote_user_header_name != undef {
    file {
      '/opt/graphite/webapp/graphite/custom_auth.py':
        ensure  => file,
        owner   => $::graphite::params::web_user,
        group   => $::graphite::params::web_user,
        mode    => '0644',
        content => template('graphite/opt/graphite/webapp/graphite/custom_auth.py.erb'),
        require => $web_server_package_require;
    }
  }

  # configure carbon engines
  if $::graphite::gr_enable_carbon_relay and $::graphite::gr_enable_carbon_aggregator {
    $notify_services = [
      Service['carbon-aggregator'],
      Service['carbon-relay'],
      Service['carbon-cache'],
      Service['carbon-cache-b']
    ]
  }
  elsif $::graphite::gr_enable_carbon_relay {
    $notify_services = [
      Service['carbon-relay'],
      Service['carbon-cache'],
      Service['carbon-cache-b']
    ]
  }
  elsif $::graphite::gr_enable_carbon_aggregator {
    $notify_services = [
      Service['carbon-aggregator'],
      Service['carbon-cache'],
      Service['carbon-cache-b']
    ]
  }
  else {
    $notify_services = [ Service['carbon-cache'], Service['carbon-cache-b'] ]
  }

  if $::graphite::gr_enable_carbon_relay {

    file {
      '/opt/graphite/conf/relay-rules.conf':
        mode    => '0644',
        content => template('graphite/opt/graphite/conf/relay-rules.conf.erb'),
        notify  => $notify_services;
    }
  }

  if $::graphite::gr_enable_carbon_aggregator {

    file {
      '/opt/graphite/conf/aggregation-rules.conf':
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/aggregation-rules.conf.erb'),
      notify  => $notify_services;
    }
  }

  file {
    '/opt/graphite/conf/storage-schemas.conf':
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/storage-schemas.conf.erb'),
      notify  => $notify_services;
    '/opt/graphite/conf/carbon.conf':
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/carbon.conf.erb'),
      notify  => $notify_services;
    '/opt/graphite/conf/storage-aggregation.conf':
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/storage-aggregation.conf.erb'),
      #notify  => $notify_services;
  }


  # configure logrotate script for carbon

  file { '/opt/graphite/bin/carbon-logrotate.sh':
    ensure  => file,
    mode    => '0544',
    content => template('graphite/opt/graphite/bin/carbon-logrotate.sh.erb'),
  }

  cron { 'Rotate carbon logs':
    command => '/opt/graphite/bin/carbon-logrotate.sh',
    user    => root,
    hour    => 1,
    minute  => 15,
    require => File['/opt/graphite/bin/carbon-logrotate.sh'];
  }

  # startup carbon engine

  service { 'carbon-cache':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => File['/etc/init.d/carbon-cache'];
  }

  service { 'carbon-cache-b':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => File['/etc/init.d/carbon-cache-b'];
  }

  file { '/etc/init.d/carbon-cache':
    ensure  => file,
    mode    => '0750',
    content => template('graphite/etc/init.d/carbon-cache.erb'),
    require => File['/opt/graphite/conf/carbon.conf'];
  }

  file { '/etc/init.d/carbon-cache-b':
    ensure  => file,
    mode    => '0750',
    content => template('graphite/etc/init.d/carbon-cache-b.erb'),
    require => File['/opt/graphite/conf/carbon.conf'];
  }

  if $graphite::gr_enable_carbon_relay {
    service { 'carbon-relay':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => File['/etc/init.d/carbon-relay'];
    }

    file { '/etc/init.d/carbon-relay':
      ensure  => file,
      mode    => '0750',
      content => template('graphite/etc/init.d/carbon-relay.erb'),
      require => File['/opt/graphite/conf/carbon.conf'];
    }
  }

  if $graphite::gr_enable_carbon_aggregator {
    service {'carbon-aggregator':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => File['/etc/init.d/carbon-aggregator'];
    }

    file { '/etc/init.d/carbon-aggregator':
      ensure  => file,
      mode    => '0750',
      content => template('graphite/etc/init.d/carbon-aggregator.erb'),
      require => File['/opt/graphite/conf/carbon.conf'];
    }
  }
}
