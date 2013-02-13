# == Class: graphite::config
#
# This class configures graphite/carbon/whisper and SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::config (
	$gr_user = '',
	$gr_max_cache_size = inf,
	$gr_max_updates_per_second = 500,
	$gr_max_creates_per_minute = 50,
	$gr_line_receiver_interface = '0.0.0.0',
	$gr_line_receiver_port = 2003,
	$gr_enable_udp_listener = False,
	$gr_udp_receiver_interface = '0.0.0.0',
	$gr_udp_receiver_port = 2003,
	$gr_pickle_receiver_interface = '0.0.0.0',
	$gr_pickle_receiver_port = 2004,
	$gr_use_insecure_unpickler = False,
	$gr_cache_query_interface = '0.0.0.0',
	$gr_cache_query_port = 7002,
	$gr_timezone = 'GMT',
	$gr_apache_port = 80,
	$gr_apache_port_https = 443
) inherits graphite::params {

	anchor { 'graphite::config::begin': }
	anchor { 'graphite::config::end': }

	Exec { path => '/bin:/usr/bin:/usr/sbin' }

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	# we need an apache with python support

	package {
		"${::graphite::params::apache_pkg}":        ensure => installed;
	}

	package {
		"${::graphite::params::apache_python_pkg}":
			ensure  => installed,
			require => Package["${::graphite::params::apache_pkg}"]
	}

	case $::osfamily {
		debian: {
			exec { 'Disable default apache site':
				command => 'a2dissite default',
				onlyif  => 'test -f /etc/apache2/sites-enabled/000-default',
				require => Package["${::graphite::params::apache_python_pkg}"],
				notify  => Service["${::graphite::params::apache_service_name}"];
			}
		}
		redhat: {
			file { "${::graphite::params::apacheconf_dir}/welcome.conf":
				ensure  => absent,
				require => Package["${::graphite::params::apache_python_pkg}"],
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
		subscribe   => Exec["Install ${::graphite::params::graphiteVersion}"],
		before      => Exec['Chown graphite for apache'];
	}

	# change access permissions for apache

	exec { 'Chown graphite for apache':
		command     => "chown -R ${::graphite::params::web_user}:${::graphite::params::web_user} /opt/graphite/storage/",
		cwd         => '/opt/graphite/',
		refreshonly => true,
		require     => Anchor['graphite::install::end'],
	}

	# Deploy configfiles

	file {
		'/opt/graphite/webapp/graphite/local_settings.py':
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template('graphite/opt/graphite/webapp/graphite/local_settings.py.erb');
		"${::graphite::params::apache_dir}/ports.conf":
			ensure  => file,
			owner   => $::graphite::params::web_user,
			group   => $::graphite::params::web_user,
			mode    => '0644',
			content => template('graphite/etc/apache2/ports.conf.erb'),
			require => [
				Package["${::graphite::params::apache_python_pkg}"],
				Exec['Initial django db creation']
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
		ensure  => present,
		mode    => '0750',
		content => template('graphite/etc/init.d/carbon-cache.erb'),
		require => File['/opt/graphite/conf/carbon.conf'];
	}
}
