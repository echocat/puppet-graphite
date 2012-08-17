class graphite::install inherits graphite::params {

  anchor { 'graphite::install::begin': }
  anchor { 'graphite::install::end': }

  case $operatingsystem {
    centos,redhat: {
      class { 'graphite::install::redhat':
        require => Anchor['graphite::install::begin'],
        before  => Anchor['graphite::install::end'],
      }
    }
    debian,ubuntu: {
      class { 'graphite::install::debian':
        require => Anchor['graphite::install::begin'],
        before  => Anchor['graphite::install::end'],
      }
    }
	default: {
		fail("Environment not suitable for installing graphite.")
	}
  }
}