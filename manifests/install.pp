# == Class: graphite::install
#
# This class installs graphite packages via pip
#
# === Parameters
#
# None.
#
class graphite::install inherits graphite::params {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optinal: python-ldap, python-memcache, memcached, python-sqlite

  if $::graphite::gr_pip_install {
    Package {
      provider => 'pip',
    }

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
  }

  package { $::graphite::params::graphitepkgs :
    ensure   => 'installed',
    provider => undef, # default to package provider auto-discovery
  }->

  package{ 'django-tagging':
      ensure => $::graphite::gr_django_tagging_ver,
      name   => $::graphite::gr_django_tagging_pkg,
  }->

  package{'twisted':
    ensure => $::graphite::gr_twisted_ver,
    name   => $::graphite::gr_twisted_pkg,
  }->

  package{'txamqp':
    ensure => $::graphite::gr_txamqp_ver,
    name   => $::graphite::gr_txamqp_pkg,
  }->

  package{'graphite-web':
    ensure => $::graphite::gr_graphite_ver,
    name   => $::graphite::gr_graphite_pkg,
  }->

  package{'carbon':
    ensure => $::graphite::gr_carbon_ver,
    name   => $::graphite::gr_carbon_pkg,
  }->

  package{'whisper':
    ensure => $::graphite::gr_whisper_ver,
    name   => $::graphite::gr_whisper_pkg,
  }

  if $::graphite::gr_pip_install {
    # workaround for unusual graphite install target:
    # https://github.com/graphite-project/carbon/issues/86
    file { $::graphite::params::carbon_pip_hack_source :
      ensure  => link,
      target  => $::graphite::params::carbon_pip_hack_target,
      require => Package['whisper'],
    }

    file { $::graphite::params::gweb_pip_hack_source :
      ensure  => link,
      target  => $::graphite::params::gweb_pip_hack_target,
      require => Package['whisper'],
    }
  }
}
