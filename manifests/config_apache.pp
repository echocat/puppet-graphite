# == Class: graphite::config_apache
#
# This class configures apache to proxy requests to graphite web and SHOULD
# NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::config_apache inherits graphite::params {
  Exec { path => '/bin:/usr/bin:/usr/sbin' }

  $virtualenv = $::graphite::params::virtualenv

  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
    before              => Exec['Chown graphite for web user'],
    notify              => Exec['Chown graphite for web user'],
  }

  # we need an apache with python support
  class { 'apache::mod::wsgi': }

  case $::osfamily {
    'Debian': {
      # mod_header is disabled on Ubuntu by default,
      # but we need it for CORS headers
      if $::graphite::gr_web_cors_allow_from_all {
        include apache::mod::headers
      }
    }
    default: {}
  }

  # Deploy configfiles

  apache::vhost { "graphite.${::domain}":
    port                        => $::graphite::gr_apache_port,
    servername                  => $::graphite::gr_web_servername,
    docroot                     => '/opt/graphite/webapp',
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => {
      processes          => '5',
      threads            => '5',
      display-name       => '%{GROUP}',
      inactivity-timeout => '120',
    },
    wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
    wsgi_import_script_options  => {
      process-group     => 'graphite',
      application-group => '%{GLOBAL}',
    },
    wsgi_process_group          => 'graphite',
    wsgi_script_aliases         => {
      '/' => '/opt/graphite/conf/graphite.wsgi',
    },
    aliases                     => [
      {
        alias => '/content/',
        path  => '/opt/graphite/webapp/content/',
      },
      {
        alias => '/media/',
        path  => '@DJANGO_ROOT@/contrib/admin/media/',
      },
    ],
    directories                 => [
      { path       => '/content/',
        provider   => 'location',
        sethandler => 'None',
      },
      { path       => '/media/',
        provider   => 'location',
        sethandler => 'None',
      },
      { path     => '/opt/graphite/conf/',
        provider => 'directory',
        order    => 'deny,allow',
        allow    => 'from all',
      },
    ],
  }

}
