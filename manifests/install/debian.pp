# == Class: graphite::install::debian
#
# This class installs graphite/carbon/whisper on Debian and its derivates and SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::install::debian {

	include graphite::params

	Exec { path => '/bin:/usr/bin:/usr/sbin' }

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	anchor { 'graphitepkg::begin': }
	anchor { 'graphitepkg::end': }

	package { $::graphite::params::graphitepkgs :
			ensure  => installed,
			require => Anchor['graphitepkg::begin'],
			before  => Anchor['graphitepkg::end']
	}

	# Download graphite sources

	exec {
		"Download and untar ${::graphite::params::graphiteVersion}":
			command => "wget -O - ${::graphite::params::webapp_dl_url} | tar xz",
			creates => "${::graphite::params::build_dir}/${::graphite::params::graphiteVersion}",
			cwd     => "${::graphite::params::build_dir}";
		"Download and untar ${::graphite::params::carbonVersion}":
			command => "wget -O - ${::graphite::params::carbon_dl_url} | tar xz",
			creates => "${::graphite::params::build_dir}/${::graphite::params::carbonVersion}",
			cwd     => "${::graphite::params::build_dir}";
		"Download and untar ${::graphite::params::whisperVersion}":
			command => "wget -O - ${::graphite::params::whisper_dl_url} | tar xz",
			creates => "${::graphite::params::build_dir}/${::graphite::params::whisperVersion}",
			cwd     => "${::graphite::params::build_dir}";
	}

	# Install graphite from source

	exec {
		"Install ${::graphite::params::graphiteVersion}":
			command     => 'python setup.py install',
			cwd         => "${::graphite::params::build_dir}/${::graphite::params::graphiteVersion}",
			subscribe   => Exec["Download and untar ${::graphite::params::graphiteVersion}"],
			refreshonly => true,
			require     => [
				Exec["Download and untar ${::graphite::params::graphiteVersion}"],
				Anchor['graphitepkg::end']
			];
		"Install ${::graphite::params::carbonVersion}":
			command     => 'python setup.py install',
			cwd         => "${::graphite::params::build_dir}/${::graphite::params::carbonVersion}",
			subscribe   => Exec["Download and untar ${::graphite::params::carbonVersion}"],
			refreshonly => true,
			require     => [
				Exec["Download and untar ${::graphite::params::carbonVersion}"],
				Anchor['graphitepkg::end']
			];
		"Install ${::graphite::params::whisperVersion}":
			command     => 'python setup.py install',
			cwd         => "${::graphite::params::build_dir}/${::graphite::params::whisperVersion}",
			subscribe   => Exec["Download and untar ${::graphite::params::whisperVersion}"],
			refreshonly => true,
			require     => [
				Exec["Download and untar ${::graphite::params::whisperVersion}"],
				Anchor["graphitepkg::end"]
			];
	}
}

