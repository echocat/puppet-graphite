# == Class: graphite::config
#
# This class configures graphite/carbon/whisper and SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::config inherits graphite::params {

	anchor { 'graphite::config::begin': }
	anchor { 'graphite::config::end': }

	Exec { path => '/bin:/usr/bin:/usr/sbin' }

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	# we need an apache with python support

	package {
		"${::graphite::params::apache_pkg}": 
			ensure => installed,
			before => Exec['Chown graphite for apache'],
			notify => Exec['Chown graphite for apache'];
	}

	package {
		"${::graphite::params::apache_wsgi_pkg}":
		ensure  => installed,
 		require => Package["${::graphite::params::apache_pkg}"]
	}

	case $::osfamily {
		debian: {
			exec { 'Disable default apache site':
				command => 'a2dissite default',
				onlyif  => 'test -f /etc/apache2/sites-enabled/000-default',
				require => Package["${::graphite::params::apache_wsgi_pkg}"],
				notify  => Service["${::graphite::params::apache_service_name}"];
			}
		}
		redhat: {
			file { "${::graphite::params::apacheconf_dir}/welcome.conf":
				ensure  => absent,
				require => Package["${::graphite::params::apache_wsgi_pkg}"],
				notify  => Service["${::graphite::params::apache_service_name}"];
			}
		}
		default: {
			fail("Module graphite is not supported on ${::operatingsystem}")
      		}
	}

	service { "${::graphite::params::apache_service_name}":
		ensure     => running,
		enable     => true,
		hasrestart => true,
		hasstatus  => true,
		require    => Exec['Chown graphite for apache'];
	}

	# first init of user db for graphite

	exec { 'Initial django db creation':
		command     => 'python manage.py syncdb --noinput',
		cwd         => '/opt/graphite/webapp/graphite',
		refreshonly => true,
		notify      => Exec['Chown graphite for apache'],
		subscribe   => Exec["Install webapp ${::graphite::params::graphiteVersion}"],
		before      => Exec['Chown graphite for apache'],
		require     => File['/opt/graphite/webapp/graphite/local_settings.py'];
	}

	# change access permissions for apache

	exec { 'Chown graphite for apache':
		command     => "chown -R ${::graphite::params::web_user}:${::graphite::params::web_user} /opt/graphite/storage/",
		cwd         => '/opt/graphite/',
		refreshonly => true,
		require     => [
			Anchor['graphite::install::end'],
			Package["${::graphite::params::apache_pkg}"]
		]
	}

	# Deploy configfiles

	file {
		'/opt/graphite/webapp/graphite/local_settings.py':
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template("graphite/opt/graphite/webapp/graphite/local_settings.py.erb"),
			require => Package["${::graphite::params::apache_pkg}"];
		'/opt/graphite/conf/graphite.wsgi':
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template("graphite/opt/graphite/conf/graphite.wsgi.erb"),
			require => Package["${::graphite::params::apache_pkg}"];
		"${::graphite::params::apache_dir}/ports.conf":
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template('graphite/etc/apache2/ports.conf.erb'),
			require => [
				Package["${::graphite::params::apache_wsgi_pkg}"],
				Exec['Initial django db creation'],
				Exec['Chown graphite for apache']
			];
		"${::graphite::params::apacheconf_dir}/graphite.conf":
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template('graphite/etc/apache2/sites-available/graphite.conf.erb'),
			require => [
				File["${::graphite::params::apache_dir}/ports.conf"],
			];
	}

	case $::osfamily {
		debian: {
			file { '/etc/apache2/sites-enabled/graphite.conf':
				ensure  => link,
				target  => "${::graphite::params::apacheconf_dir}/graphite.conf",
				require => File['/etc/apache2/sites-available/graphite.conf'],
				notify  => Service["${::graphite::params::apache_service_name}"];
			}
		}
		default: {}
	}

	# configure carbon engine

	file {
		'/opt/graphite/conf/storage-schemas.conf':
			mode    => '0644',
			content => template('graphite/opt/graphite/conf/storage-schemas.conf.erb'),
			require => Anchor['graphite::install::end'],
			notify  => Service['carbon-cache'];
		'/opt/graphite/conf/carbon.conf':
			mode    => '0644',
			content => template('graphite/opt/graphite/conf/carbon.conf.erb'),
			require => Anchor['graphite::install::end'],
			notify  => Service['carbon-cache'];
	}


	# configure logrotate script for carbon

	file { '/opt/graphite/bin/carbon-logrotate.sh':
		ensure  => file,
		mode    => '0544',
		content => template('graphite/opt/graphite/bin/carbon-logrotate.sh.erb'),
		require => Anchor['graphite::install::end'];
	}

	cron { 'Rotate carbon logs':
		command => '/opt/graphite/bin/carbon-logrotate.sh',
		user    => root,
		hour    => 1,
		minute  => 15,
		require => File['/opt/graphite/bin/carbon-logrotate.sh'];
	}

	# startup carbon engine

	service { 'carbon-cache':
		ensure     => running,
		enable     => true,
		hasstatus  => true,
		hasrestart => true,
		before     => Anchor['graphite::config::end'],
		require    => File['/etc/init.d/carbon-cache'];
	}

	file { '/etc/init.d/carbon-cache':
		ensure  => file,
		mode    => '0750',
		content => template('graphite/etc/init.d/carbon-cache.erb'),
		require => File['/opt/graphite/conf/carbon.conf'];
	}
}
