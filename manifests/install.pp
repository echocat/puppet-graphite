# == Class: graphite::install
#
# This class installs graphite packages via pip
#
# === Parameters
#
# None.
#
class graphite::install(
  $django_tagging_ver = '0.3.1',
  $twisted_ver        = '11.1.0',
  $txamqp_ver         = '0.4',
  $graphite_web_loc   = 'graphite-web',
  $carbon_loc         = 'carbon',
  $whisper_loc        = 'whisper',
) inherits graphite::params {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  Package {
    provider => 'pip',
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  # using the pip package provider requires python-pip

  if ! defined(Package[$::graphite::params::python_pip_pkg]) {
    package { $::graphite::params::python_pip_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  # install python headers and libs for pip

  if ! defined(Package[$::graphite::params::python_dev_pkg]) {
    package { $::graphite::params::python_dev_pkg :
      provider => undef, # default to package provider auto-discovery
      before   => [
        Package['django-tagging'],
        Package['twisted'],
        Package['txamqp'],
      ]
    }
  }

  package { $::graphite::params::graphitepkgs :
    ensure   => 'installed',
    provider => undef, # default to package provider auto-discovery
  }->

  package{'django-tagging':
    ensure => $django_tagging_ver,
  }->

  package{'twisted':
    ensure => $twisted_ver,
    name   => 'Twisted',
  }->

  package{'txamqp':
    ensure => $txamqp_ver,
    name   => 'txAMQP',
  }->

  package{'graphite-web':
    ensure => installed,
    name => $graphite_web_loc,
  }->

  package{'carbon':
    ensure => installed,
    name => $carbon_loc,
  }->

  package{'whisper':
    ensure => installed,
    name => $whisper_loc
  }->

  # workaround for unusual graphite install target:
  # https://github.com/graphite-project/carbon/issues/86
  file { $::graphite::params::carbon_pip_hack_source :
    ensure => link,
    target => $::graphite::params::carbon_pip_hack_target,
  }->

  file { $::graphite::params::gweb_pip_hack_source :
    ensure => link,
    target => $::graphite::params::gweb_pip_hack_target,
  }
}
