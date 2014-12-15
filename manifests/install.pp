# == Class: graphite::install
#
# This class installs graphite packages via pip
# and installs the OS specific packages via the
# the system package provider.
#
# === Parameters
#
# [* django_ver *]
#  version of django to install. Default=1.4
# [* django_tagging_ver *]
#  version of django-tagging. Default=0.3.0
# [* twisdted_ver *]
#  version of twisted. Default=11.1.0
# [* django_txampq_ver *]
#  version of txamqp. Default=0.4.0
#
# === Requirements
#
# stankevich-python module:
# to manage the the python installation
# and provide virtualenv capabilities
#
class graphite::install(
  $django_ver         = '1.4',
  $django_tagging_ver = '0.3.1',
  $twisted_ver        = '11.1.0',
  $txamqp_ver         = '0.4',
) inherits graphite::params {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optional: python-ldap, python-memcache, memcached, python-sqlite

  $install_virtualenv = $graphite::python_provider ? {
    'system'     => false,
    'virtualenv' => true,
  }

  class { 'python':
    version    => 'system',
    dev        => true,
    pip        => true,
    virtualenv => $install_virtualenv,
  }

  # Install OS specfic packages (deb, rpm, etc)
  package { $::graphite::params::graphitepkgs :
    ensure   => 'installed',
  }

  # Hash of packages to install via pip
  $pip_requirements = {
    'Django'         => {
      ensure => $django_ver,
    },
    'django-tagging' => {
      ensure => $django_tagging_ver,
    },
    'Twisted'        => {
      ensure => $twisted_ver,
      before => Python::Pip['txAMQP'],
    },
    'txAMQP'         => {
      ensure => $txamqp_ver,
    },
    'graphite-web'   => {
      name   => 'graphite-web',
      ensure => $::graphite::params::graphiteVersion,
    },
    'carbon'         => {
      ensure => $::graphite::params::carbonVersion,
    },
    'whisper'        => {
      ensure => $::graphite::params::whisperVersion,
    },
    'pycrypto'       => {},
    'pysqlite'       => {},
    'zope.interface' => {},
  }

  # We need to set /opt/graphite/{lib,webapp} paths so
  # pip knows were to find graphite-web and carbon installs
  # see https://github.com/graphite-project/carbon/issues/86
  $pip_environment = [
    'PYTHONPATH=/opt/graphite/lib/:/opt/graphite/webapp/',
  ]

  # If virtualenv has been enabled, set up the
  # environment before installing pip packages
  if $graphite::python_provider == 'virtualenv' {

    $virtualenv = $graphite::params::virtualenv
    python::virtualenv { $virtualenv:
      ensure     => present,
      systempkgs => true,
      version    => system,
      require    => Package[$::graphite::params::graphitepkgs]
    }

    $pip_defaults = {
      ensure      => present,
      virtualenv  => $virtualenv,
      environment => $pip_environment,
      require     => Python::Virtualenv[$virtualenv]
    }

  } else {

    $pip_defaults = {
      ensure      => present,
      environment => $pip_environment,
    }

  }

  # Now install all the pip packages
  create_resources(python::pip, $pip_requirements, $pip_defaults)

}
