# == Class: graphite::config_gunicorn
#
# This class configures graphite/carbon/whisper and SHOULD NOT be
# called directly.
#
# === Parameters
#
# None.
#
class graphite::config_gunicorn inherits graphite::params {
  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  if $::osfamily == 'Debian' {
    $package_name = 'gunicorn'

  } elsif $::osfamily == 'RedHat' {
    $package_name = 'python-gunicorn'

  } else {
    fail("wsgi/gunicorn-based graphite is not supported on ${::operatingsystem} (only supported on Debian & RedHat)")
  }

  if $::service_provider == 'systemd' or ($::service_provider == 'debian' and $::operatingsystemmajrelease == '8') {
    
    file { '/etc/systemd/system/gunicorn.service':
      ensure  => file,
      content => template('graphite/etc/systemd/gunicorn.service.erb'),
      mode    => '0644',
    }

    file { '/etc/systemd/system/gunicorn.socket':
      ensure  => file,
      content => template('graphite/etc/systemd/gunicorn.socket.erb'),
      mode    => '0755',
    }

    file { '/etc/tmpfiles.d/gunicorn.conf':
      ensure  => file,
      content => template('graphite/etc/tmpfiles.d/gunicorn.conf.erb'),
      mode    => '0644',
    }

    exec { 'gunicorn-reload-systemd':
      command => 'systemctl daemon-reload',
      path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      require => [
        File['/etc/systemd/system/gunicorn.service'],
        File['/etc/systemd/system/gunicorn.socket'],
        File['/etc/tmpfiles.d/gunicorn.conf'],
      ],
      before  => Service['gunicorn']
    }
    # These next two are needed for Debian for some reason
    ->
    exec { 'stop gunicorn-socket':
      command => 'systemctl stop gunicorn.socket',
      path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      before  => Service['gunicorn']
    }
    ->
    exec { 'start gunicorn-socket':
      command => 'systemctl start gunicorn.socket',
      path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      before  => Service['gunicorn']
    }

  } elsif $::service_provider == 'redhat' {

    file { '/etc/init.d/gunicorn':
      ensure  => file,
      content => template('graphite/etc/init.d/RedHat/gunicorn.erb'),
      mode    => '0755',
    }

  }

  file { '/opt/graphite/webapp/graphite/wsgi.py':
    ensure => link,
    target => '/opt/graphite/conf/graphite.wsgi',
    before => Service['gunicorn'],
  }

  # fix graphite's race condition on start
  # if the exec fails, assume we're using a version of graphite that doesn't need it
  if $graphite::gunicorn_workers > 1 {
    file { '/tmp/fix-graphite-race-condition.py':
      ensure => file,
      source => 'puppet:///modules/graphite/fix-graphite-race-condition.py',
      mode   => '0755',
    }
    exec { 'fix graphite race condition':
      command     => 'python /tmp/fix-graphite-race-condition.py',
      cwd         => '/opt/graphite/webapp',
      environment => 'DJANGO_SETTINGS_MODULE=graphite.settings',
      user        => $graphite::gr_web_user_REAL,
      logoutput   => true,
      group       => $graphite::gr_web_group_REAL,
      require     => [
        File['/tmp/fix-graphite-race-condition.py'],
        Exec['Initial django db creation'],
        Service['carbon-cache'],
      ],
      before      => Service['gunicorn'],
    }
  }

  package {
    $package_name:
      ensure => installed;
  }

  service { 'gunicorn':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => [
      File['/opt/graphite/storage/run'],
      File['/opt/graphite/storage/log'],
      Exec['Initial django db creation'],
      Package[$package_name],
    ],
    subscribe  => File['/opt/graphite/webapp/graphite/local_settings.py'],
  }

  # Deploy configfiles
  if $::osfamily == 'Debian' {
    file { '/etc/gunicorn.d/graphite':
      ensure  => file,
      content => template('graphite/etc/gunicorn.d/graphite.erb'),
      mode    => '0644',
      before  => Service['gunicorn'],
      require => Package[$package_name],
    }
  }
}
