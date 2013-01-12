class graphite::params {
	$build_dir = "/usr/local/src/"

	$graphiteVersion = "graphite-web-0.9.10"
	$carbonVersion = "carbon-0.9.10"
	$whisperVersion = "whisper-0.9.10"

	$whisper_dl_url = "http://launchpad.net/graphite/0.9/0.9.10/+download/${whisperVersion}.tar.gz"
	$whisper_dl_loc = "$build_dir/whisper.tar.gz"

	$webapp_dl_url = "http://launchpad.net/graphite/0.9/0.9.10/+download/${graphiteVersion}.tar.gz"
	$webapp_dl_loc = "$build_dir/graphite-web.tar.gz"

	$carbon_dl_url = "http://launchpad.net/graphite/0.9/0.9.10/+download/${carbonVersion}.tar.gz"
	$carbon_dl_loc = "$build_dir/carbon.tar.gz"

	$install_prefix = "/opt/"

	$apache_pkg = $::osfamily ? {
		debian => "apache2",
		redhat => "httpd",
	}

	$apache_python_pkg = $::osfamily ? {
		debian => "libapache2-mod-python",
		redhat => "mod_python",
	}

	$apache_service_name = $::osfamily ? {
		debian => "apache2",
		redhat => "httpd",
	}

	$web_user = $::osfamily ? {
		debian => "www-data",
		redhat => "apache",
	}

	$apacheconf_dir = $::osfamily ? {
		debian => "/etc/apache2/sites-available",
		redhat => "/etc/httpd/conf.d",
	}

	$graphitepkgs = $::osfamily ? {
		debian => ["python-cairo","python-twisted","python-django","python-django-tagging","python-ldap","python-memcache","python-sqlite","python-simplejson"],
		redhat => ["pycairo", "Django", "python-ldap", "python-memcached", "python-sqlite2",  "bitmap", "bitmap-fonts-compat", "python-devel", "python-crypto", "pyOpenSSL", "gcc", "python-zope-filesystem", "python-zope-interface", "git", "gcc-c++", "zlib-static", "MySQL-python"],
	}
 
}
