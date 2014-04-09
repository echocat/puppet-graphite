#graphite

####Table of Contents

1. [Overview - What is the graphite module?](#overview)
2. [Module Description - What does this module do?](#module-description)
3. [Setup - The basics of getting started with graphite](#setup)
    * [Beginning with graphite - Installation](#beginning-with-graphite)
    * [Configure MySQL and Memcached](#configure-mysql-and-memcached)
    * [Configuration with Apache 2.4 and CORS](#configuration-with-apache-24-and-cors)
4. [Usage - The class and available configurations](#usage)
7. [Requirements](#requirements)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Contributing to the graphite module](#contributing)

##Overview

This module installs and makes basic configs for graphite, with carbon and whisper.

##Module Description

[Graphite](http://graphite.readthedocs.org/en/latest/overview.html), and its components Carbon and Whispter, is an enterprise-scale monitoring tool. This module sets up a simple graphite server with all its components. Furthermore it can be used to set up more complex graphite environments with metric aggregation, clustering and so on.

##Setup

**What graphite affects:**

* packages/services/configuration files for Graphite
* on default sets up webserver (can be disabled if manage by other module)

###Beginning with Graphite

To install Graphite with default parameters

```puppet
    class { 'graphite': }
```

The defaults are determined by your operating system e.g. Debian systems have one set of defaults, and RedHat systems have another). This defaults should work well on testing environments with graphite as a standalone service on the machine. For production use it is recommend to use a database like MySQL and cache data in memcached (not installed with this module) and configure it here. Furthermore you should check things like `gr_storage_schemas`.

###Configure MySQL and Memcached

```puppet
  class { 'graphite':
    gr_max_updates_per_second => 100,
    gr_timezone               => 'Europe/Berlin',
    secret_key                => 'CHANGE_IT!',
    gr_storage_schemas        => [
      {
        name       => 'carbon',
        pattern    => '^carbon\.',
        retentions => '1m:90d'
      },
      {
        name       => 'special_server',
        pattern    => '^longtermserver_',
        retentions => '10s:7d,1m:365d,10m:5y'
      },
      {
        name       => 'default',
        pattern    => '.*',
        retentions => '60:43200,900:350400'
      }
    ],
    gr_django_db_engine       => 'django.db.backends.mysql',
    gr_django_db_name         => 'graphite',
    gr_django_db_user         => 'graphite',
    gr_django_db_password     => 'MYsEcReT!',
    gr_django_db_host         => 'mysql.my.domain',
    gr_django_db_port         => '3306',
    gr_memcache_hosts         => ['127.0.0.1:11211']
  }
```

###Configuration with Apache 2.4 and CORS

If you use a system which ships Apache 2.4, then you will need a slightly different vhost config.
Here is an example with Apache 2.4 and [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) enabled.
If you do not know what CORS, then do not use it. Its disabled by default.

```puppet
  class { 'graphite':
    gr_apache_24               => true,
    gr_web_cors_allow_from_all => true,
    secret_key                 => 'CHANGE_IT!'
  }
```

##Usage

####Class: `graphite`

This is the primary class. And the only one which should be used.

**Parameters within `graphite`:**

#####`gr_user`

Default is empty. The user who runs graphite. If this is empty carbon runs as the user that invokes it.

#####`gr_max_cache_size`

Default is 'inf'. Limits the size of the cache to avoid swapping or becoming CPU bound. Use the value "inf" (infinity) for an unlimited cache size.

#####`gr_max_updates_per_second`

Default is 500. Limits the number of whisper update_many() calls per second, which effectively means the number of write requests sent to the disk.

#####`gr_max_creates_per_minute`

Default is 50. Softly limits the number of whisper files that get created each minute.

#####`gr_carbon_metric_interval`

Default is 60. Set the interval between sending internal performance metrics; affects all carbon daemons.

#####`gr_line_receiver_interface`

Default is '0.0.0.0' (string). Interface the line receiver listens.

#####`gr_line_receiver_port`

Default is 2003. Port of line receiver.

#####`gr_enable_udp_listener`

Default is 'False' (string). Set this to True to enable the UDP listener.

#####`gr_udp_receiver_interface`

Default is '0.0.0.0' (string). Its clear, isnt it?

#####`gr_udp_receiver_port`

Default is 2003. Self explaining.

#####`gr_pickle_receiver_interface`

Default is '0.0.0.0' (string). Pickle is a special receiver who handle tuples of data.

#####`gr_pickle_receiver_port`

Default is 2004. Self explaining

#####`gr_use_insecure_unpickler`

Default is 'False' (string). Set this to 'True' to revert to the old-fashioned insecure unpickler.

#####`gr_use_whitelist`

Default is 'False' (string). Set this to 'True' to enable whitelists and blacklists.

#####`gr_cache_query_interface`

Default is '0.0.0.0'. Interface to send cache queries to.

#####`gr_cache_query_port`

Default is 7002. Self explaining.

#####`gr_timezone`

Default is 'GMT' (string). Timezone for graphite to be used.

#####`gr_storage_schemas`

Default is
```
[
  {
    name       => 'carbon',
    pattern    => '^carbon\.',
    retentions => '1m:90d'
  },
  {
    name       => 'default',
    pattern    => '.*',
    retentions => '1s:30m,1m:1d,5m:2y'
  }
]
```
The storage schemas, which describes how long matching graphs are to be stored in detail.

#####`gr_storage_aggregation_rules`

Default is the Hashmap:
```
{
  '00_min'         => { pattern => '\.min$',   factor => '0.1', method => 'min' },
  '01_max'         => { pattern => '\.max$',   factor => '0.1', method => 'max' },
  '02_sum'         => { pattern => '\.count$', factor => '0.1', method => 'sum' },
  '99_default_avg' => { pattern => '.*',       factor => '0.5', method => 'average'}
}
```
The storage aggregation rules.

#####`gr_web_server`

Default is 'apache'. The web server to use. Valid values are 'apache', 'nginx', 'wsgionly' or 'none'. 'nginx' is only supported on Debian-like systems. And 'none' means that you will manage the webserver yourself.

#####`gr_web_servername`

Default is `$::fqdn` (string). Virtualhostname of Graphite webgui.

#####`gr_web_cors_allow_from_all`

Default is false (boolean). Include CORS Headers for all hosts (*) in web server config.

#####`gr_apache_port`

Default is 80. The HTTP port apache will use.

#####`gr_apache_port_https`

Default is 443. The HTTPS port apache will use.

#####`gr_apache_24`

Default is false (boolean). If you set this to 'true' and use 'apache' in `gr_web_server`, then the configuration for Apache 2.4 is used, else it will be Apache 2.2 compatible configuration.

#####`gr_django_1_4_or_less`

Default is false (boolean). Django settings style.

#####`gr_django_db_engine`

Default is 'django.db.backends.sqlite3' (string). Can be set to

- django.db.backends.postgresql  <- Removed in Django 1.4
- django.db.backends.postgresql_psycopg2
- django.db.backends.mysql
- django.db.backends.sqlite3
- django.db.backends.oracle

#####`gr_django_db_name`

Default is '/opt/graphite/storage/graphite.db' (string). Name of database to be used by django.

#####`gr_django_db_user`

Default is '' (string). Name of database user.

#####`gr_django_db_password`

Default is '' (string). Password of database user.

#####`gr_django_db_host`

Default is '' (string). Hostname/IP of database server.

#####`gr_django_db_port`

Default is '' (string). Port of database.

#####`gr_enable_carbon_aggregator`

Default is false (boolean) Enable the carbon aggregator daemon.

#####`gr_aggregator_line_interface`

Default is '0.0.0.0' (string). Address for line interface to listen on.

#####`gr_aggregator_line_port`

Default is 2023. TCP port for line interface to listen on.

#####`gr_aggregator_pickle_interface`

Default is '0.0.0.0' (string). IP address for pickle interface.

#####`gr_aggregator_pickle_port`

Default is 2024. Pickle port.

#####`gr_aggregator_forward_all`

Default is 'True' (string). Forward all metrics to the destination(s) defined in  `gr_aggregator_destinations`.

#####`gr_aggregator_destinations`

Default is [ '127.0.0.1:2004' ] (array). Array of backend carbons.

#####`gr_aggregator_max_queue_size`

Default is 10000. Maximum queue size.

#####`gr_aggregator_use_flow_control`

Default is 'True' (string). Enable flow control Can be True or False.

#####`gr_aggregator_max_intervals`

Default is 5. Maximum number intervals to keep around.

#####`gr_aggregator_rules`

Default is
```
{
  'carbon-class-mem'  => 'carbon.all.<class>.memUsage (60) = sum carbon.<class>.*.memUsage',
  'carbon-all-mem'    => 'carbon.all.memUsage (60) = sum carbon.*.*.memUsage',
}
```
Hashmap of carbon aggregation rules.

#####`gr_memcache_hosts`

Default is undef (array). List of memcache hosts to use. eg ['127.0.0.1:11211','10.10.10.1:11211']

#####`secret_key`

Default is 'UNSAFE_DEFAULT' (string). CHANGE IT! Secret used as salt for things like hashes, cookies, sessions etc. Has to be the same on all nodes of a graphite cluster.

#####`nginx_htpasswd`

Default is undef (string). The user and salted SHA-1 (SSHA) password for Nginx authentication. If set, Nginx will be configured to use HTTP Basic authentication with the given user & password. e.g.: 'testuser:$jsfak3.c3Fd0i1k2kel/3sdf3'

#####`manage_ca_certificate`

Default is true (boolean). Used to determine if the module should install ca-certificate on Debian machines during the initial installation.

#####`gr_use_ldap`

Default is false (boolean). Turn ldap authentication on/off.

#####`gr_ldap_uri`

Default is '' (string). Set ldap uri.

#####`gr_ldap_search_base`

Default is '' (string). Set the ldap search base.

#####`gr_ldap_base_user`

Default is '' (string).Set ldap base user.

#####`gr_ldap_base_pass`

Default is '' (string). Set ldap password.

#####`gr_ldap_user_query`

Default is '(username=%s)' (string). Set ldap user query.

#####`gr_use_remote_user_auth`

Default is 'False' (string). Allow use of REMOTE_USER env variable within Django/Graphite.

#####`gr_remote_user_header_name`

Default is undef. Allows the use of a custom HTTP header, instead of the REMOTE_USER env variable (mainly for nginx use) to tell Graphite a user is authenticated. Useful when using an external auth handler with X-Accel-Redirect etc.
Example value - HTTP_X_REMOTE_USER
The specific use case for this is OpenID right now, but could be expanded to anything.
One example is something like http://antoineroygobeil.com/blog/2014/2/6/nginx-ruby-auth/
combined with the option `gr_web_server` = 'wsgionly' and http://forge.puppetlabs.com/jfryman/nginx
with some custom vhosts.
The sample external auth app is available from [here](https://github.com/antoinerg/nginx_auth_backend)

##Requirements

###Modules needed:

stdlib by puppetlabs

###Software versions needed:

facter > 1.6.2
puppet > 2.6.2

On Redhat distributions you need the EPEL or RPMforge repository, because Graphite needs packages, which are not part of the default repos.

##Limitations

This module is tested on CentOS 6.5 and Debian 7 (Wheezy) and should also run without problems on

* RHEL/CentOS/Scientific 6+
* Debian 6+
* Ubunutu 10.04 and newer

Most settings of Graphite can be set by parameters. So their can be special configurations for you. In this case you should edit
the file `templates/opt/graphite/webapp/graphite/local_settings.py.erb`.

The nginx configs are only supported on Debian based systems at the moment.

##Contributing

Echocat modules are open projects. So if you want to make this module even better, you can contribute to this module on [Github](https://github.com/echocat/puppet-graphite).
