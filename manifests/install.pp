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
  $twisted_ver = '11.1.0',
  $txamqp_ver = '0.4',
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

  package { $::graphite::params::graphitepkgs :
    ensure   => 'installed',
    provider => undef, # default to package provider auto-discovery
  }

  # using the pip package provider requires python-pip
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

  package{'django-tagging':
    ensure   => $django_tagging_ver,
  }->
  package{'twisted':
    ensure   => $twisted_ver,
  }->
  package{'txamqp':
    ensure   => $txamqp_ver,
  }->
  package{'graphite-web':
    ensure   => $::graphite::params::graphiteVersion,
  }->
  package{'carbon':
    ensure   => $::graphite::params::carbonVersion,
  }->
  package{'whisper':
    ensure   => $::graphite::params::whisperVersion,
  }->

  # workaround for unusual graphite install target:
  # https://github.com/graphite-project/carbon/issues/86
  file { $::graphite::params::carbin_pip_hack_source :
    ensure => link,
    target => $::graphite::params::carbin_pip_hack_target,
  }->
  file { $::graphite::params::gweb_pip_hack_source :
    ensure => link,
    target => $::graphite::params::gweb_pip_hack_target,
  }

}
