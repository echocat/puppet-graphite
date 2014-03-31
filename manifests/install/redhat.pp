# == Class: graphite::install::redhat
#
# This class installs graphite/carbon/whisper on Redhat and its derivates and SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::install::redhat {

  include graphite::params

  Exec {
    cwd  => $::graphite::params::webapp_dl_loc,
    path => '/bin:/usr/bin:/usr/sbin',
  }

  Package {
    ensure  => installed,
  }

  # for full functionality we need this packages:
  # madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  package { $::graphite::params::graphitepkgs :}

  # Install required python env special for redhat and derivatives

  package { 'python-setuptools':}

  exec {
    'Install django-tagging':
      command => 'easy_install django-tagging==0.3.1',
    'Install twisted':
      command => 'easy_install twisted==11.1.0',
    'Install txamqp':
      command => 'easy_install txamqp==0.4',
  }

  # Download graphite sources

  exec {
    "Download and untar webapp ${::graphite::params::graphiteVersion}":
      command => "curl -s -L ${::graphite::params::webapp_dl_url} | tar xz",
      creates => "${::graphite::params::webapp_dl_loc}",
      cwd     => "${::graphite::params::build_dir}";
    "Download and untar carbon ${::graphite::params::carbonVersion}":
      command => "curl -s -L ${::graphite::params::carbon_dl_url} | tar xz",
      creates => "${::graphite::params::carbon_dl_loc}",;
    "Download and untar whisper ${::graphite::params::whisperVersion}":
      command => "curl -s -L ${::graphite::params::whisper_dl_url} | tar xz",
      creates => "${::graphite::params::whisper_dl_loc}",
  }

  # Install graphite from source

  exec {
    "Install webapp ${::graphite::params::graphiteVersion}":
      command     => 'python setup.py install',
      cwd         => $::graphite::params::webapp_dl_loc,
      subscribe   => Exec["Download and untar webapp ${::graphite::params::graphiteVersion}"],
      refreshonly => true,
      require     => [
        Exec["Download and untar webapp ${::graphite::params::graphiteVersion}"],
        Exec["Install django-tagging"]
      ];
    "Install carbon ${::graphite::params::carbonVersion}":
      command     => 'python setup.py install',
      cwd         => $::graphite::params::carbon_dl_loc,
      subscribe   => Exec["Download and untar carbon ${::graphite::params::carbonVersion}"],
      refreshonly => true,
      require     => [
        Exec["Download and untar carbon ${::graphite::params::carbonVersion}"],
        Exec["Install twisted"]
      ];
    "Install whisper ${::graphite::params::whisperVersion}":
      command     => 'python setup.py install',
      cwd         => $::graphite::params::whisper_dl_loc,
      subscribe   => Exec["Download and untar whisper ${::graphite::params::whisperVersion}"],
      refreshonly => true,
      require     => [
        Exec["Download and untar whisper ${::graphite::params::whisperVersion}"],
        Exec["Install twisted"]
      ];
  }
}

