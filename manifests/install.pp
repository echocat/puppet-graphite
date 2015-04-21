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

    unless $::osfamily =~ /(Debian|RedHat)/ {
      fail('unsupported os.')
    }

    $carbon_pip_hack_source = $::osfamily ? {
      'Debian' => "/usr/lib/python2.7/dist-packages/carbon-${::graphite::gr_carbon_ver}-py2.7.egg-info",
      'RedHat' => $::operatingsystemrelease ? {
        /^6\.\d+$/ => "/usr/lib/python2.6/site-packages/carbon-${::graphite::gr_carbon_ver}-py2.6.egg-info",
        /^7\.\d+/  => "/usr/lib/python2.7/site-packages/carbon-${::graphite::gr_carbon_ver}-py2.7.egg-info",
        default    => fail("Unsupported RedHat release: '${::operatingsystemrelease}'"),
      },
    }

    $carbon_pip_hack_target = $::osfamily ? {
      'Debian' => "/opt/graphite/lib/carbon-${::graphite::gr_carbon_ver}-py2.7.egg-info",
      'RedHat' => $::operatingsystemrelease ? {
        /^6\.\d+$/ => "/opt/graphite/lib/carbon-${::graphite::gr_carbon_ve}-py2.6.egg-info",
        /^7\.\d+/  => "/opt/graphite/lib/carbon-${::graphite::gr_carbon_ve}-py2.7.egg-info",
        default    => fail("Unsupported RedHat release: '${::operatingsystemrelease}'"),
      },
    }

    $gweb_pip_hack_source = $::osfamily ? {
      'Debian' => "/usr/lib/python2.7/dist-packages/graphite_web-${::graphite::gr_graphite_ver}-py2.7.egg-info",
      'RedHat' => $::operatingsystemrelease ? {
        /^6\.\d+$/ => "/usr/lib/python2.6/site-packages/graphite_web-${::graphite::gr_graphite_ver}-py2.6.egg-info",
        /^7\.\d+/  => "/usr/lib/python2.7/site-packages/graphite_web-${::graphite::gr_graphite_ver}-py2.7.egg-info",
        default    => fail("Unsupported RedHat release: '${::operatingsystemrelease}'"),
      },
    }

    $gweb_pip_hack_target = $::osfamily ? {
      'Debian' => "/opt/graphite/webapp/graphite_web-${::graphite::gr_graphite_ver}-py2.7.egg-info",
      'RedHat' => $::operatingsystemrelease ? {
        /^6\.\d+$/ => "/opt/graphite/webapp/graphite_web-${::graphite::gr_graphite_ver}-py2.6.egg-info",
        /^7\.\d+/  => "/opt/graphite/webapp/graphite_web-${::graphite::gr_graphite_ver}-py2.7.egg-info",
        default    => fail("Unsupported RedHat release: '${::operatingsystemrelease}'"),
      },
    }

    file { $carbon_pip_hack_source :
      ensure  => link,
      target  => $carbon_pip_hack_target,
      require => Package['whisper'],
    }

    file { $gweb_pip_hack_source :
      ensure  => link,
      target  => $gweb_pip_hack_target,
      require => Package['whisper'],
    }
  }
}
