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

  $python_pip_pkg = 'python-pip'
  $graphiteVersion = '0.9.12'
  $carbonVersion   = '0.9.12'
  $whisperVersion  = '0.9.12'

  $whisper_dl_url = "http://github.com/graphite-project/whisper/archive/${::graphite::params::whisperVersion}.tar.gz"
  $whisper_dl_loc = "${build_dir}/whisper-${::graphite::params::whisperVersion}"

  $webapp_dl_url = "http://github.com/graphite-project/graphite-web/archive/${::graphite::params::graphiteVersion}.tar.gz"
  $webapp_dl_loc = "${build_dir}/graphite-web-${::graphite::params::graphiteVersion}"

  $carbon_dl_url = "https://github.com/graphite-project/carbon/archive/${::graphite::params::carbonVersion}.tar.gz"
  $carbon_dl_loc = "${build_dir}/carbon-${::graphite::params::carbonVersion}"

  $install_prefix = '/opt/'
  $enable_carbon_relay = false
  $nginxconf_dir = '/etc/nginx/sites-available'


  case $::osfamily {
    'debian': {
      $apache_pkg = 'apache2'
      $apache_wsgi_pkg = 'libapache2-mod-wsgi'
      $apache_wsgi_socket_prefix = '/var/run/apache2/wsgi'
      $apache_service_name = 'apache2'
      $apacheconf_dir = '/etc/apache2/sites-available'
      $apacheports_file = 'ports.conf'
      $apache_dir = '/etc/apache2'
      $web_user = 'www-data'
      $python_dev_pkg = 'python-dev'

      # see https://github.com/graphite-project/carbon/issues/86
      $carbin_pip_hack_source = "/usr/lib/python2.7/dist-packages/carbon-${carbonVersion}-py2.7.egg-info"
      $carbin_pip_hack_target = "/opt/graphite/lib/carbon-${carbonVersion}-py2.7.egg-info"
      $gweb_pip_hack_source = "/usr/lib/python2.7/dist-packages/graphite_web-${carbonVersion}-py2.7.egg-info"
      $gweb_pip_hack_target = "/opt/graphite/webapp/graphite_web-${carbonVersion}-py2.7.egg-info"

      $graphitepkgs = [
        'python-cairo',
        'python-twisted',
        'python-django',
        'python-django-tagging',
        'python-ldap',
        'python-memcache',
        'python-sqlite',
        'python-simplejson',
        'python-mysqldb'
      ]
    }
    'redhat': {
      $apache_pkg = 'httpd'
      $apache_wsgi_pkg = 'mod_wsgi'
      $apache_wsgi_socket_prefix = 'run/wsgi'
      $apache_service_name = 'httpd'
      $apacheconf_dir = '/etc/httpd/conf.d'
      $apacheports_file = 'graphite_ports.conf'
      $apache_dir = '/etc/httpd'
      $web_user = 'apache'
      $python_dev_pkg = 'python-devel'

      # see https://github.com/graphite-project/carbon/issues/86
      case $::operatingsystemrelease {
        /^6\.\d+$/: {
          $carbin_pip_hack_source = "/usr/lib/python2.6/site-packages/carbon-${carbonVersion}-py2.6.egg-info"
          $carbin_pip_hack_target = "/opt/graphite/lib/carbon-${carbonVersion}-py2.6.egg-info"
          $gweb_pip_hack_source = "/usr/lib/python2.6/site-packages/graphite_web-${graphiteVersion}-py2.6.egg-info"
          $gweb_pip_hack_target = "/opt/graphite/webapp/graphite_web-${graphiteVersion}-py2.6.egg-info"
        }
        /^7\.\d+$/: {
          $carbin_pip_hack_source = "/usr/lib/python2.7/site-packages/carbon-${carbonVersion}-py2.7.egg-info"
          $carbin_pip_hack_target = "/opt/graphite/lib/carbon-${carbonVersion}-py2.7.egg-info"
          $gweb_pip_hack_source = "/usr/lib/python2.7/site-packages/graphite_web-${graphiteVersion}-py2.7.egg-info"
          $gweb_pip_hack_target = "/opt/graphite/webapp/graphite_web-${graphiteVersion}-py2.7.egg-info"
        }
        default: {fail('Unsupported Redhat release')}
      }

      $graphitepkgs = [
        'pycairo',
        'Django14',
        'python-ldap',
        'python-memcached',
        'python-sqlite2',
        'bitmap',
        'bitmap-fonts-compat',
        'python-crypto',
        'pyOpenSSL',
        'gcc',
        'python-zope-filesystem',
        'python-zope-interface',
        'MySQL-python'
      ]
    }
    default: {fail('unsupported os.')}
  }

  $web_server_pkg = $graphite::gr_web_server ? {
    apache   => $apache_pkg,
    nginx    => 'nginx',
    wsgionly => 'dont-install-webserver-package',
    none     => 'dont-install-webserver-package',
    default  => fail('The only supported web servers are \'apache\', \'nginx\',  \'wsgionly\' and \'none\''),
  }

}
