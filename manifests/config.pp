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

  # we need an web server with python support
  # apache with mod_wsgi or nginx with gunicorn
  case $graphite::gr_web_server {
    'apache'   : {
      include graphite::config_apache
      $web_server_package_require = [Package[$::graphite::params::apache_pkg]]
    }

    'nginx'    : {
      # Configure gunicorn and nginx.
      include graphite::config_gunicorn
      include graphite::config_nginx
      $web_server_package_require = [Package['nginx']]
    }

    'wsgionly' : {
      # Configure gunicorn only without nginx.
      include graphite::config_gunicorn
      $web_server_package_require = undef
    }

    'none'     : {
      # Don't configure apache, gunicorn or nginx. Leave all webserver configuration to something external.
      $web_server_package_require = undef
    }

    default    : {
      fail('The only supported web servers are \'apache\', \'nginx\', \'wsgionly\' and \'none\'')
    }
  }

  # first init of user db for graphite

  exec { 'Initial django db creation':
    command     => 'python manage.py syncdb --noinput',
    cwd         => '/opt/graphite/webapp/graphite',
    refreshonly => true,
    require     => File['/opt/graphite/webapp/graphite/local_settings.py'],
    subscribe   => Class['graphite::install'],
  } ~>
  # change access permissions for web server

  file { [
    '/opt/graphite/storage',
    '/opt/graphite/storage/lists',
    '/opt/graphite/storage/log',
    '/opt/graphite/storage/log/webapp',
    '/opt/graphite/storage/rrd',
    '/opt/graphite/storage/run']:
    ensure  => directory,
    group   => $::graphite::gr_web_group,
    mode    => '0755',
    owner   => $::graphite::gr_web_user,
    seltype => 'httpd_sys_rw_content_t',
    notify  => Exec['set_graphite_defaults', 'set_graphite_storage_defaults', 'restorecon_graphite'],
  }

  file { '/opt/graphite/':
    ensure => directory,
    group  => $::graphite::gr_web_group,
    mode   => '0755',
    owner  => $::graphite::gr_web_user,
    before => File['/opt/graphite/storage'],
    notify => Exec['set_graphite_defaults', 'set_graphite_storage_defaults', 'restorecon_graphite'],
  }

  # change access permissions for carbon-cache to align with gr_user
  # (if different from web_user)

  if $::graphite::gr_user != '' {
    $carbon_user  = $::graphite::gr_user
    $carbon_group = $::graphite::gr_group
  } else {
    $carbon_user  = $::graphite::gr_web_user
    $carbon_group = $::graphite::gr_web_group
  }

  file {
    '/opt/graphite/storage/whisper':
      ensure  => directory,
      group   => $carbon_group,
      mode    => '0755',
      owner   => $carbon_user,
      path    => $::graphite::gr_local_data_dir,
      seltype => 'httpd_sys_rw_content_t';

    '/opt/graphite/storage/log/carbon-cache':
      ensure  => directory,
      group   => $carbon_group,
      mode    => '0755',
      owner   => $carbon_user,
      seltype => 'httpd_sys_rw_content_t';
  }

  # Lets ensure graphite.db owner is the same as gr_web_user
  file { '/opt/graphite/storage/graphite.db':
    ensure  => file,
    group   => $::graphite::gr_web_group,
    mode    => '0644',
    owner   => $::graphite::gr_web_user,
    seltype => 'httpd_sys_rw_content_t';
  }

  # Deploy configfiles
  file {
    '/opt/graphite/webapp/graphite/local_settings.py':
      ensure  => file,
      content => template('graphite/opt/graphite/webapp/graphite/local_settings.py.erb'),
      group   => $::graphite::gr_web_group,
      mode    => '0644',
      owner   => $::graphite::gr_web_user,
      require => $web_server_package_require,
      seltype => 'httpd_sys_content_t';

    '/opt/graphite/conf/graphite.wsgi':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/graphite.wsgi.erb'),
      group   => $::graphite::gr_web_group,
      mode    => '0644',
      owner   => $::graphite::gr_web_user,
      require => $web_server_package_require,
      seltype => 'httpd_sys_content_t';
  }

  if $::graphite::gr_remote_user_header_name {
    file { '/opt/graphite/webapp/graphite/custom_auth.py':
      ensure  => file,
      content => template('graphite/opt/graphite/webapp/graphite/custom_auth.py.erb'),
      group   => $::graphite::gr_web_group,
      mode    => '0644',
      owner   => $::graphite::gr_web_user,
      require => $web_server_package_require,
      seltype => 'httpd_sys_rw_content_t',
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

  $notify_services = delete_undef_values([$service_cache, $service_relay, $service_aggregator])

  if $::graphite::gr_enable_carbon_relay {
    file { '/opt/graphite/conf/relay-rules.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/relay-rules.conf.erb'),
      mode    => '0644',
      notify  => $notify_services,
      seltype => 'httpd_sys_content_t',
    }
  }

  if $::graphite::gr_enable_carbon_aggregator {
    file { '/opt/graphite/conf/aggregation-rules.conf':
      ensure  => file,
      mode    => '0644',
      content => template('graphite/opt/graphite/conf/aggregation-rules.conf.erb'),
      notify  => $notify_services,
      seltype => 'httpd_sys_content_t',
    }
  }

  file {
    '/opt/graphite/conf/storage-schemas.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/storage-schemas.conf.erb'),
      mode    => '0644',
      notify  => $notify_services,
      seltype => 'httpd_sys_content_t';

    '/opt/graphite/conf/carbon.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/carbon.conf.erb'),
      mode    => '0644',
      notify  => $notify_services,
      seltype => 'httpd_sys_content_t';

    '/opt/graphite/conf/storage-aggregation.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/storage-aggregation.conf.erb'),
      mode    => '0644',
      seltype => 'httpd_sys_content_t';

    '/opt/graphite/conf/whitelist.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/whitelist.conf.erb'),
      mode    => '0644',
      seltype => 'httpd_sys_content_t';

    '/opt/graphite/conf/blacklist.conf':
      ensure  => file,
      content => template('graphite/opt/graphite/conf/blacklist.conf.erb'),
      mode    => '0644',
      seltype => 'httpd_sys_content_t';
  } ->
  # set selinux directory context
  exec { 'set_graphite_defaults':
    command     => 'semanage fcontext -a -t httpd_sys_content_t "/opt/graphite(/.*)?"',
    path        => '/bin:/usr/bin/:/sbin:/usr/sbin',
    refreshonly => true,
  } ->
  exec { 'set_graphite_storage_defaults':
    command     => 'semanage fcontext -a -t httpd_sys_rw_content_t "/opt/graphite/storage(/.*)?"',
    path        => '/bin:/usr/bin/:/sbin:/usr/sbin',
    refreshonly => true,
  } ->
  exec { 'restorecon_graphite':
    command     => 'restorecon -R /opt/graphite',
    path        => '/bin:/usr/bin/:/sbin:/usr/sbin',
    before      => Service['httpd'],
    refreshonly => true,
  }

  # configure logrotate script for carbon
  file { '/opt/graphite/bin/carbon-logrotate.sh':
    ensure  => file,
    mode    => '0544',
    content => template('graphite/opt/graphite/bin/carbon-logrotate.sh.erb'),
  }

  cron { 'Rotate carbon logs':
    command => '/opt/graphite/bin/carbon-logrotate.sh',
    hour    => 1,
    minute  => 15,
    require => File['/opt/graphite/bin/carbon-logrotate.sh'],
    user    => root,
  }

  # startup carbon engine

  if $graphite::gr_enable_carbon_cache {
    service { 'carbon-cache':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => File['/etc/init.d/carbon-cache'],
    }

    file { '/etc/init.d/carbon-cache':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-cache.erb"),
      mode    => '0750',
      require => File['/opt/graphite/conf/carbon.conf'],
    }
  }

  if $graphite::gr_enable_carbon_relay {
    service { 'carbon-relay':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => File['/etc/init.d/carbon-relay'],
    }

    file { '/etc/init.d/carbon-relay':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-relay.erb"),
      mode    => '0750',
      require => File['/opt/graphite/conf/carbon.conf'],
    }
  }

  if $graphite::gr_enable_carbon_aggregator {
    service { 'carbon-aggregator':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => File['/etc/init.d/carbon-aggregator'],
    }

    file { '/etc/init.d/carbon-aggregator':
      ensure  => file,
      content => template("graphite/etc/init.d/${::osfamily}/carbon-aggregator.erb"),
      mode    => '0750',
      require => File['/opt/graphite/conf/carbon.conf'],
    }
  }
}
