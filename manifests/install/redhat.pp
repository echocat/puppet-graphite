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
    provider => 'pip',
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  package { $::graphite::params::graphitepkgs :}

  # using the pip package provider requires python-pip on redhat
  if ! defined(Package['python-pip']) {
    package { 'python-pip':
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  package{'django-tagging':
    ensure   => '0.3.1',
  }->
  package{'twisted':
    ensure   => '11.1.0',
  }->
  package{'txamqp':
    ensure   => '0.4',
  }->
  package{'graphite-web':
    ensure   => $::graphite::params::graphiteVersion,
  }->
  package{'carbon':
    ensure   => $::graphite::params::carbonVersion,
  }->
  package{'whisper':
    ensure   => $::graphite::params::whisperVersion,
  }

}

