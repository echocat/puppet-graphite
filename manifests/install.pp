# == Class: graphite::install
#
# This class calls the OS specific install classes and SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::install inherits graphite::params(
  manage_git = true,
) {

  anchor { 'graphite::install::begin': }
  anchor { 'graphite::install::end': }

  case $::osfamily {
    redhat: {
      class { 'graphite::install::redhat':
        manage_git => $manage_git,
        require    => Anchor['graphite::install::begin'],
        before     => Anchor['graphite::install::end'],
      }
    }
        debian: {
      class { 'graphite::install::debian':
        require => Anchor['graphite::install::begin'],
        before  => Anchor['graphite::install::end'],
      }
    }
    default: {
      fail("Module graphite is not supported on ${::operatingsystem}")
    }
  }
}
