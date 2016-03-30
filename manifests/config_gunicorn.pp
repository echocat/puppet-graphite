# == Class: graphite::config_gunicorn
#
# This class configures graphite/carbon/whisper and SHOULD NOT be
# called directly.
#
# === Parameters
#
# None.
#
class graphite::config_gunicorn inherits graphite::params {
  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  case $::osfamily {
    
    'Debian': {
      $package_name = 'gunicorn'

      # Debian has a wrapper script called `gunicorn-debian` for multiple gunicorn 
      # configs. Each config is stored as a separate file in /etc/gunicorn.d/. 
      # On debian 8 and Ubuntu 15.10, which use systemd, the gunicorn-debian
      # config file has to be installed before the gunicorn package. 
      file { '/etc/gunicorn.d/':
        ensure => directory,
      }
      file { '/etc/gunicorn.d/graphite':
        ensure  => file,
        content => template('graphite/etc/gunicorn.d/graphite.erb'),
        mode    => '0644',
        before  => Package[$package_name],
        require => File['/etc/gunicorn.d/'],
      }
    }

    'RedHat': {
      $package_name = 'python-gunicorn'

      # RedHat package is missing initscript
      if $::service_provider == 'systemd' {

        file { '/etc/systemd/system/gunicorn.service':
          ensure  => file,
          content => template('graphite/etc/systemd/gunicorn.service.erb'),
          mode    => '0644',
        }

        file { '/etc/systemd/system/gunicorn.socket':
          ensure  => file,
          content => template('graphite/etc/systemd/gunicorn.socket.erb'),
          mode    => '0755',
        }

        file { '/etc/tmpfiles.d/gunicorn.conf':
          ensure  => file,
          content => template('graphite/etc/tmpfiles.d/gunicorn.conf.erb'),
          mode    => '0644',
        }

        exec { 'gunicorn-reload-systemd':
          command => 'systemctl daemon-reload',
          path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
          require => [
            File['/etc/systemd/system/gunicorn.service'],
            File['/etc/systemd/system/gunicorn.socket'],
            File['/etc/tmpfiles.d/gunicorn.conf'],
          ],
          before  => Service['gunicorn']
        }

      } elsif $::service_provider == 'redhat' {

        file { '/etc/init.d/gunicorn':
          ensure  => file,
          content => template('graphite/etc/init.d/RedHat/gunicorn.erb'),
          mode    => '0755',
          before  => Service['gunicorn'],
        }

      }

    }

    default: {
      fail("wsgi/gunicorn-based graphite is not supported on ${::operatingsystem} (only supported on Debian & RedHat)")
    }

  }

  # The `gunicorn-debian` command doesn't require this, as it
  # uses the deprecated `gunicorn_django` command. But, I hope
  # that debian will eventually update their gunicorn package
  # to use the non-deprecated version.
  file { "${graphite::gr_graphiteweb_install_lib_dir}/wsgi.py":
    ensure => link,
    target => "${graphite::gr_graphiteweb_conf_dir}/graphite.wsgi",
    before => Service['gunicorn'],
  }

  # fix graphite's race condition on start
  # if the exec fails, assume we're using a version of graphite that doesn't need it
  if $graphite::gunicorn_workers > 1 {
    file { '/tmp/fix-graphite-race-condition.py':
      ensure => file,
      source => 'puppet:///modules/graphite/fix-graphite-race-condition.py',
      mode   => '0755',
    }
    exec { 'fix graphite race condition':
      command     => 'python /tmp/fix-graphite-race-condition.py',
      cwd         => $graphite::gr_graphiteweb_webapp_dir,
      environment => 'DJANGO_SETTINGS_MODULE=graphite.settings',
      user        => $graphite::config::gr_web_user_REAL,
      logoutput   => true,
      group       => $graphite::config::gr_web_group_REAL,
      returns     => [0, 1],
      require     => [
        File['/tmp/fix-graphite-race-condition.py'],
        Exec['Initial django db creation'],
        Service['carbon-cache'],
      ],
      before      => Package[$package_name],
    }
  }

  # Only install gunicorn after graphite is ready to go
  package {
    $package_name:
      ensure  => installed,
      require => [
        File[$graphite::gr_pid_dir],
        File[$graphite::gr_graphiteweb_log_dir],
        Exec['Initial django db creation'],
      ];
  }

  service { 'gunicorn':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => [
      Package[$package_name],
    ],
    subscribe  => File["${graphite::gr_graphiteweb_conf_dir}/local_settings.py"],
  }

}
