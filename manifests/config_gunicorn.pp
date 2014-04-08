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

  if $::osfamily != 'debian' {
    fail("wsgi/gunicorn-based graphite is not supported on ${::operatingsystem} (only supported on Debian)")
  }

  package {
    'gunicorn':
      ensure => installed,
      before => Exec['Chown graphite for web user'],
      notify => Exec['Chown graphite for web user'];

  }

  service {
    'gunicorn':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => false,
      subscribe  => File['/opt/graphite/webapp/graphite/local_settings.py'],
      require    => [
        Package['gunicorn'],
        Exec['Initial django db creation'],
        Exec['Chown graphite for web user']
      ];
  }

  # Deploy configfiles

  file {
    '/etc/gunicorn.d/graphite':
      ensure  => file,
      mode    => '0644',
      content => template('graphite/etc/gunicorn.d/graphite.erb'),
      require => Package['gunicorn'],
      notify  => Service['gunicorn'];
  }

}
