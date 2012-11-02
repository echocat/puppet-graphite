class graphite::config (
	$gr_user = "",
	$gr_max_cache_size = "inf",
	$gr_max_updates_per_second = 500,
	$gr_max_creates_per_minute = 50,
	$gr_line_receiver_interface = "0.0.0.0",
	$gr_line_receiver_port = 2003,
	$gr_enable_udp_listener = "False",
	$gr_udp_receiver_interface = "0.0.0.0",
	$gr_udp_receiver_port = 2003,
	$gr_pickle_receiver_interface = "0.0.0.0",
	$gr_pickle_receiver_port = 2004,
	$gr_use_insecure_unpickler = "False",
	$gr_cache_query_interface = "0.0.0.0",
	$gr_cache_query_port = 7002
) inherits graphite::params {

	anchor { 'graphite::config::begin': }
	anchor { 'graphite::config::end': }

	Exec {
		path => '/bin:/usr/bin:/usr/sbin',
	}

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	# we need an apache with python support

	package {
		$apache_pkg: ensure => installed;
		$apache_python_pkg: ensure => installed;
	}

	case $operatingsystem {

		ubuntu,debian: {
			exec { "Disable default apache site":
				command => "a2dissite default",
				onlyif => "test -f /etc/apache2/sites-enabled/000-default",
				require => Package["$apache_pkg"],
				notify => Service["$apache_service_name"];
			}
		}
		redhat,centos: {
			file { "${apacheconf_dir}/welcome.conf":
				ensure => absent,
				require => Package["$apache_pkg"],
               	notify => Service["$apache_service_name"];
			}
		}
	}

	service {
		"$apache_service_name":
			hasrestart => true,
			hasstatus => true,
			ensure => running,
			enable => true,
			require => Exec["Chown graphite for apache"];
	}

	# first init of user db for graphite

	exec {
		"Initial django db creation":
			command => "python manage.py syncdb --noinput",
			cwd => "/opt/graphite/webapp/graphite",
			refreshonly => true,
			notify => Exec["Chown graphite for apache"],
			subscribe => Exec["Install $graphiteVersion"],
			before => Exec["Chown graphite for apache"];
	}

	# change access permissions for apache

	exec {
		"Chown graphite for apache":
			command => "chown -R $web_user:$web_user /opt/graphite/storage/",
			cwd => "/opt/graphite/",
			refreshonly => true,
			require => Anchor["graphite::install::end"],
	}

	# Deploy configfiles

	file {
		"/opt/graphite/webapp/graphite/local_settings.py":
			mode => 644,
			owner => "$web_user",
			group => "$web_user",
			content => template("graphite/opt/graphite/webapp/graphite/local_settings.py.erb");
		"${apacheconf_dir}/graphite.conf":
			mode => 644,
			owner => "$web_user",
			group => "$web_user",
			content => template("graphite/etc/apache2/sites-available/graphite.conf.erb"),
			require => [Package["$apache_pkg"],Exec["Initial django db creation"]];
	}

	case $operatingsystem {
		ubuntu,debian: {
			file {
				"/etc/apache2/sites-enabled/graphite.conf":
					ensure => link,
					target => "${apacheconf_dir}/graphite.conf",
					require => File["/etc/apache2/sites-available/graphite.conf"],
					notify => Service["$apache_service_name"];
			}
		}
	}

	# configure carbon engine

	file {
		"/opt/graphite/conf/storage-schemas.conf":
			mode => 644,
			content => template("graphite/opt/graphite/conf/storage-schemas.conf.erb"),
			require => Anchor["graphite::install::end"],
			notify => Service["carbon-cache"];
		"/opt/graphite/conf/carbon.conf":
			mode => 644,
			content => template("graphite/opt/graphite/conf/carbon.conf.erb"),
			require => Anchor["graphite::install::end"],
			notify => Service["carbon-cache"];
	}

	# startup carbon engine

	service {
		"carbon-cache":
			hasstatus => true,
			hasrestart => true,
			ensure => running,
			enable => true,
			before => Anchor['graphite::config::end'],
			require => File["/etc/init.d/carbon-cache"];
	}

	file {
		"/etc/init.d/carbon-cache":
			ensure => present,
			mode => 750,
			content => template("graphite/etc/init.d/carbon-cache.erb"),
			require => File["/opt/graphite/conf/carbon.conf"];
	}
}
