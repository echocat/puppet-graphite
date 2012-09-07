class graphite::install::debian {

	require graphite::params

  Exec {
    path => '/bin:/usr/bin:/usr/sbin',
  }

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	anchor { "graphitepkg::begin": }
	anchor { "graphitepkg::end": }

	package {
		$graphitepkgs:
			ensure => installed,
			require => Anchor["graphitepkg::begin"],
			before => Anchor["graphitepkg::end"]
	}

	# Download graphite sources

	exec {
		"Download and untar $graphiteVersion":
			command => "wget -O - $webapp_dl_url | tar xz",
			creates => "${build_dir}/$graphiteVersion",
			cwd => "$build_dir";
		"Download and untar $carbonVersion":
			command => "wget -O - $carbon_dl_url | tar xz",
			creates => "${build_dir}/$carbonVersion",
			cwd => "$build_dir";
		"Download and untar $whisperVersion":
			command => "wget -O - $whisper_dl_url | tar xz",
			creates => "${build_dir}/$whisperVersion",
			cwd => "$build_dir";
	}

	# Install graphite from source

	exec {
		"Install $graphiteVersion":
			command => "python setup.py install",
			cwd => "${build_dir}/$graphiteVersion",
			subscribe => Exec["Download and untar $graphiteVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $graphiteVersion"],Anchor["graphitepkg::end"]];
		"Install $carbonVersion":
			command => "python setup.py install",
			cwd => "${build_dir}/$carbonVersion",
			subscribe => Exec["Download and untar $carbonVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $carbonVersion"],Anchor["graphitepkg::end"]];
		"Install $whisperVersion":
			command => "python setup.py install",
			cwd => "${build_dir}/$whisperVersion",
			subscribe => Exec["Download and untar $whisperVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $whisperVersion"],Anchor["graphitepkg::end"]];
	}

	# initialize database

	# Because the django isntall of debian sucks we have to 
	# create our own symlinks to python lib dir.
	# you find your lib dir wiht: 
	#   python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()";
	file {
		"/usr/lib/python2.6/dist-packages/django":
			ensure => link,
			target => "/usr/lib/pymodules/python2.6/django",
			require => Anchor["graphitepkg::end"];
	}
	
}

