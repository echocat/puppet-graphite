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

	$apache_pkg = $operatingsystem ? {
		ubuntu => "apache2",
		debian => "apache2",
		rhel   => "httpd",
		centos => "httpd"
	}

	$apache_python_pkg = $operatingsystem ? {
		ubuntu => "libapache2-mod-python",
		debian => "libapache2-mod-python",
		rhel   => "mod_python",
		centos => "mod_python"
	}

	$apache_service_name = $operatingsystem ? {
		ubuntu => "apache2",
		debian => "apache2",
		rhel   => "httpd",
		centos => "httpd"
	}

	$web_user = $operatingsystem ? {
		ubuntu => "www-data",
		debian => "www-data",
		rhel   => "apache",
		centos => "apache"
	}

	$apacheconf_dir = $operatingsystem ? {
		ubuntu => "/etc/apache2/sites-available",
		debian => "/etc/apache2/sites-available",
		rhel   => "/etc/httpd/conf.d",
		centos => "/etc/httpd/conf.d"
	}

	$graphitepkgs = $operatingsystem ? {
		ubuntu => ["python-cairo","python-twisted","python-django","python-django-tagging","python-ldap","python-memcache","python-sqlite","python-simplejson"],
		debian => ["python-cairo","python-twisted","python-django","python-django-tagging","python-ldap","python-memcache","python-sqlite","python-simplejson"],
		rhel   => ["pycairo", "Django", "python-ldap", "python-memcached", "python-sqlite2",  "bitmap", "bitmap-fonts-compat", "python-devel", "python-crypto", "pyOpenSSL", "gcc", "python-zope-filesystem", "python-zope-interface", "git", "gcc-c++", "zlib-static", "MySQL-python"],
		centos => ["pycairo", "Django", "python-ldap", "python-memcached", "python-sqlite2",  "bitmap", "bitmap-fonts-compat", "python-devel", "python-crypto", "pyOpenSSL", "gcc", "python-zope-filesystem", "python-zope-interface", "git", "gcc-c++", "zlib-static", "MySQL-python"]
	}
 
}
