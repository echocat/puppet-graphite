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

    package {
      'gunicorn':
        ensure => installed,
        before => Exec['Chown graphite for web user'],
        notify => Exec['Chown graphite for web user'];
    }

    service { 'gunicorn':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      require    => [
        Exec['Chown graphite for web user'],
        Exec['Initial django db creation'],
        Package['gunicorn'],
      ],
      subscribe  => File['/opt/graphite/webapp/graphite/local_settings.py'],
    }

    # Deploy configfiles

    file { '/etc/gunicorn.d/graphite':
      ensure  => file,
      content => template('graphite/etc/gunicorn.d/graphite.erb'),
      mode    => '0644',
      notify  => Service['gunicorn'],
      require => Package['gunicorn'],
    }
  } elsif $::osfamily == 'RedHat' {

    package {
      'python-gunicorn':
        ensure => installed,
        before => Exec['Chown graphite for web user'],
        notify => Exec['Chown graphite for web user'];
    }
  } else {
    fail("wsgi/gunicorn-based graphite is not supported on ${::operatingsystem} (only supported on Debian & RedHat)")
  }
}
