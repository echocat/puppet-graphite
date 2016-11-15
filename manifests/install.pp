# == Class: graphite::install
#
# This class installs graphite packages via pip
#
# === Parameters
#
# None.
#
class graphite::install inherits graphite::params {
  # # Validate
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $::graphite::gr_pip_install and $::osfamily == 'RedHat' {
    validate_re($::operatingsystemrelease, '^[6-7]\.\d+|^20\d{2}.\d{2}', "Unsupported RedHat release: '${::operatingsystemrelease}'")
  }

  # # Set class variables
  $gr_pkg_provider = $::graphite::gr_pip_install ? {
    default => undef,
    true    => 'pip',
  }

  if $::graphite::gr_manage_python_packages {
    $gr_pkg_require = $::graphite::gr_pip_install ? {
      default => undef,
      true    => [
        Package[$::graphite::params::graphitepkgs],
        Package[$::graphite::params::python_pip_pkg],
        Package[$::graphite::params::python_dev_pkg],
        ],
    } } else {
    $gr_pkg_require = $::graphite::gr_pip_install ? {
      default => undef,
      true    => [Package[$::graphite::params::graphitepkgs],],
    } }

  $carbon = "carbon-${::graphite::gr_carbon_ver}-py${::graphite::params::pyver}.egg-info"
  $gweb   = "graphite_web-${::graphite::gr_graphite_ver}-py${::graphite::params::pyver}.egg-info"

  # # Manage resources

  # for full functionality we need these packages:
  # madatory: python-cairo, python-django, python-twisted,
  #           python-django-tagging, python-simplejson
  # optional: python-ldap, python-memcache, memcached, python-sqlite

  ensure_packages($::graphite::params::graphitepkgs, {
      before => Package['carbon']
  })

  create_resources('package', {
    'carbon'         => {
      ensure => $::graphite::gr_carbon_ver,
      name   => $::graphite::gr_carbon_pkg,
      source => $::graphite::gr_carbon_source,
    }
    ,
    'django-tagging' => {
      ensure => $::graphite::gr_django_tagging_ver,
      name   => $::graphite::gr_django_tagging_pkg,
      source => $::graphite::gr_django_tagging_source,
    }
    ,
    'graphite-web'   => {
      ensure => $::graphite::gr_graphite_ver,
      name   => $::graphite::gr_graphite_pkg,
      source => $::graphite::gr_graphite_source,
    }
    ,
    'twisted'        => {
      ensure => $::graphite::gr_twisted_ver,
      name   => $::graphite::gr_twisted_pkg,
      source => $::graphite::gr_twisted_source,
      before => [
        Package['txamqp'],
        Package['carbon'],
        ],
    }
    ,
    'txamqp'         => {
      ensure => $::graphite::gr_txamqp_ver,
      name   => $::graphite::gr_txamqp_pkg,
      source => $::graphite::gr_txamqp_source,
    }
    ,
    'whisper'        => {
      ensure => $::graphite::gr_whisper_ver,
      name   => $::graphite::gr_whisper_pkg,
      source => $::graphite::gr_whisper_source,
    }
    ,
  }
  , {
    provider => $gr_pkg_provider,
    require  => $gr_pkg_require,
  }
  )

  if $::graphite::gr_django_pkg {
    package { $::graphite::gr_django_pkg:
      ensure   => $::graphite::gr_django_ver,
      provider => $::graphite::gr_django_provider,
      source   => $::graphite::gr_django_source,
    }
  }

  if $::graphite::gr_pip_install {
    # using the pip package provider requires python-pip
    # also install python headers and libs for pip
    if $::graphite::gr_manage_python_packages {
      ensure_packages(flatten([
        $::graphite::params::python_pip_pkg,
        $::graphite::params::python_dev_pkg,
        ]))
    }

    # hack unusual graphite install target
    create_resources('file', {
      'carbon_hack' => {
        path   => "${::graphite::params::libpath}/${carbon}",
        target => "${::graphite::base_dir_REAL}/lib/${carbon}"
      }
      ,
      'gweb_hack'   => {
        path   => "${::graphite::params::libpath}/${gweb}",
        target => "${::graphite::base_dir_REAL}/webapp/${gweb}"
      }
      ,
    }
    , {
      ensure  => 'link',
      require => Package[
        'carbon', 'graphite-web', 'whisper'],
    }
    )
  }
}
