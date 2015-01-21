# == Class: graphite::params
#
# This class specifies default parameters for the graphite module and
# SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#
class graphite::params {
  $build_dir = '/usr/local/src/'

  $python_pip_pkg  = 'python-pip'
  $graphiteVersion = '0.9.12'
  $carbonVersion   = '0.9.12'
  $whisperVersion  = '0.9.12'

  $whisper_dl_url = "http://github.com/graphite-project/whisper/archive/${::graphite::params::whisperVersion}.tar.gz"
  $whisper_dl_loc = "${build_dir}/whisper-${::graphite::params::whisperVersion}"

  $webapp_dl_url = "http://github.com/graphite-project/graphite-web/archive/${::graphite::params::graphiteVersion}.tar.gz"
  $webapp_dl_loc = "${build_dir}/graphite-web-${::graphite::params::graphiteVersion}"

  $carbon_dl_url = "https://github.com/graphite-project/carbon/archive/${::graphite::params::carbonVersion}.tar.gz"
  $carbon_dl_loc = "${build_dir}/carbon-${::graphite::params::carbonVersion}"

  $install_prefix      = '/opt/'
  $enable_carbon_relay = false
  $nginxconf_dir       = '/etc/nginx/sites-available'

  case $::osfamily {
    'Debian': {
      $apache_dir                = '/etc/apache2'
      $apache_pkg                = 'apache2'
      $apache_service_name       = 'apache2'
      $apache_wsgi_pkg           = 'libapache2-mod-wsgi'
      $apache_wsgi_socket_prefix = '/var/run/apache2/wsgi'
      $apacheconf_dir            = '/etc/apache2/sites-available'
      $apacheports_file          = 'ports.conf'

      if $graphite::gr_web_group {
        $web_group = $graphite::gr_web_group
      } else {
        $web_group = 'www-data'
      }

      if $graphite::gr_web_user {
        $web_user = $graphite::gr_web_user
      } else {
        $web_user = 'www-data'
      }

      $python_dev_pkg = 'python-dev'

      # see https://github.com/graphite-project/carbon/issues/86
      $carbon_pip_hack_source = "/usr/lib/python2.7/dist-packages/carbon-${carbonVersion}-py2.7.egg-info"
      $carbon_pip_hack_target = "/opt/graphite/lib/carbon-${carbonVersion}-py2.7.egg-info"
      $gweb_pip_hack_source   = "/usr/lib/python2.7/dist-packages/graphite_web-${graphiteVersion}-py2.7.egg-info"
      $gweb_pip_hack_target   = "/opt/graphite/webapp/graphite_web-${graphiteVersion}-py2.7.egg-info"

      $graphitepkgs = [
        'python-tz',
        'python-cairo',
        'python-django',
        'python-ldap',
        'python-memcache',
        'python-mysqldb',
        'python-psycopg2',
        'python-simplejson',
        'python-sqlite',
        'python-twisted',
      ]

      case $::lsbdistcodename {
        /squeeze|wheezy|precise/: {
          $apache_24               = false
        }

        /jessie|trusty|utopic|vivid/: {
          $apache_24               = true
        }

        default: {
          fail("Unsupported Debian release: '${::lsbdistcodename}'")
        }
      }
    }

    'RedHat': {
      $apache_dir                = '/etc/httpd'
      $apache_pkg                = 'httpd'
      $apache_service_name       = 'httpd'
      $apache_wsgi_pkg           = 'mod_wsgi'
      $apache_wsgi_socket_prefix = 'run/wsgi'
      $apacheconf_dir            = '/etc/httpd/conf.d'
      $apacheports_file          = 'graphite_ports.conf'

      if $graphite::gr_web_group {
        $web_group = $graphite::gr_web_group
      } else {
        $web_group = 'apache'
      }

      if $graphite::gr_web_user {
        $web_user = $graphite::gr_web_user
      } else {
        $web_user = 'apache'
      }

      $python_dev_pkg = 'python-devel'

      # see https://github.com/graphite-project/carbon/issues/86
      case $::operatingsystemrelease {
        /^6\.\d+$/: {
          $carbon_pip_hack_source     = "/usr/lib/python2.6/site-packages/carbon-${carbonVersion}-py2.6.egg-info"
          $carbon_pip_hack_target     = "/opt/graphite/lib/carbon-${carbonVersion}-py2.6.egg-info"
          $apache_24               = false
          $gweb_pip_hack_source       = "/usr/lib/python2.6/site-packages/graphite_web-${graphiteVersion}-py2.6.egg-info"
          $gweb_pip_hack_target       = "/opt/graphite/webapp/graphite_web-${graphiteVersion}-py2.6.egg-info"
          $graphitepkgs = [
            'Django14',
            'MySQL-python',
            'bitmap',
            'bitmap-fonts-compat',
            'gcc',
            'pyOpenSSL',
            'pycairo',
            'python-crypto',
            'python-ldap',
            'python-memcached',
            'python-psycopg2',
            'python-sqlite2',
            'python-zope-interface',
          ]
        }

        /^7\.\d+/: {
          $carbon_pip_hack_source     = "/usr/lib/python2.7/site-packages/carbon-${carbonVersion}-py2.7.egg-info"
          $carbon_pip_hack_target     = "/opt/graphite/lib/carbon-${carbonVersion}-py2.7.egg-info"
          $apache_24               = true
          $gweb_pip_hack_source       = "/usr/lib/python2.7/site-packages/graphite_web-${graphiteVersion}-py2.7.egg-info"
          $gweb_pip_hack_target       = "/opt/graphite/webapp/graphite_web-${graphiteVersion}-py2.7.egg-info"
          $graphitepkgs = [
            'python-django',
            'MySQL-python',
            'bitmap',
            'bitmap-fonts-compat',
            'gcc',
            'pyOpenSSL',
            'pycairo',
            'python-crypto',
            'python-ldap',
            'python-memcached',
            'python-psycopg2',
            'python-sqlite3dbm',
            'python-zope-interface',
          ]
        }

        default: {
          fail("Unsupported RedHat release: '${::operatingsystemrelease}'")
        }
      }
    }

    default: {
      fail('unsupported os.')
    }
  }

}
