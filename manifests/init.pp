# == Class: graphite
#
# This class installs and configures graphite/carbon/whisper.
#
# === Parameters
#
# [*gr_user*]
#   The user who runs graphite. If this is empty carbon runs as the user that
#   invokes it.
#   Default is empty.
# [*gr_max_cache_size*]
#   Limit the size of the cache to avoid swapping or becoming CPU bound. Use
#   the value "inf" (infinity) for an unlimited cache size.
#   Default is inf.
# [*gr_max_updates_per_second*]
#   Limits the number of whisper update_many() calls per second, which
#   effectively means the number of write requests sent to the disk.
#   Default is 500.
# [*gr_max_creates_per_minute*]
#   Softly limits the number of whisper files that get created each minute.
#   Default is 50.
# [*gr_carbon_metric_interval*]
#   The interval (in seconds) between sending internal performance metrics.
#   Default is 60; 0 to disable instrumentation
# [*gr_line_receiver_interface*]
#   Interface the line receiver listens.
#   Default is 0.0.0.0
# [*gr_line_receiver_port*]
#   Port of line receiver.
#   Default is 2003
# [*gr_enable_udp_listener*]
#   Set this to True to enable the UDP listener.
#   Default is False.
# [*gr_udp_receiver_interface*]
#   Its clear, isnt it?
#   Default is 0.0.0.0
# [*gr_udp_receiver_port*]
#   Self explaining.
#   Default is 2003
# [*gr_pickle_receiver_interface*]
#   Pickle is a special receiver who handle tuples of data.
#   Default is 0.0.0.0
# [*gr_pickle_receiver_port*]
#   Self explaining.
#   Default is 2004
# [*gr_use_insecure_unpickler*]
#   Set this to True to revert to the old-fashioned insecure unpickler.
#   Default is False.
#[*gr_use_whitelist*]
#   Set this to True to allow for using whitelists and blacklists.
#   Default is False.
# [*gr_cache_query_interface*]
#   Interface to send cache queries to.
#   Default is 0.0.0.0
# [*gr_cache_query_port*]
#   Self explaining.
#   Default is 7002.
# [*gr_timezone*]
#   Timezone for graphite to be used.
#   Default is GMT.
# [*gr_storage_schemas*]
#  The storage schemas.
#  Default is
#  [{name => "default", pattern => ".*", retentions => "1s:30m,1m:1d,5m:2y"}]
# [*gr_storage_aggregation_rules*]
#   rule set for storage aggregation ... items get sorted, first match wins
#   pattern = <regex>
#   factor = <float between 0 and 1>
#   method = <average|sum|last|max|min>
#   Default is :
#   {
#     '00_min' => {
#       pattern => '\.min$',
#       factor => '0.1',
#       method => 'min'
#     },
#     '01_max' => {
#       pattern => '\.max$',
#       factor => '0.1',
#       method => 'max' },
#     '01_sum' => {
#       pattern => '\.count$',
#       factor => '0.1',
#       method => 'sum'
#     },
#     '99_default_avg' => {
#       pattern => '.*',
#       factor => '0.5',
#       method => 'average'
#     }
#   }
#   (matches the exammple configuration from graphite 0.9.12)
# [*gr_web_server*]
#   The web server to use.
#   Valid values are 'apache', 'nginx', 'wsgionly' and 'none'. 'nginx' is only
#   supported on Debian-like systems.
#   'wsgionly' will omit apache and nginx, allowing you to run your own
#   webserver and communicate via wsgi to the unix socket. Handy for servers
#   with multiple vhosts/purposes etc.
#   'none' will do the same as wsgionly but skips gunicorn also, omitting
#   apache and gunicorn/nginx. All other webserver settings below are
#   irrelevant if this is 'wsgionly' or 'none'.
#   Default is 'apache'.
# [*gr_web_servername*]
#   Virtualhostname of Graphite webgui.
#   Default is FQDN.
# [*gr_web_cors_allow_from_all*]
#   Include CORS Headers for all hosts (*) in web server config
#   Default is false.
# [*gr_apache_port*]
#   The port to run graphite web server on.
#   Default is 80.
# [*gr_apache_port_https*]
#   The port to run SSL web server on if you have an existing web server on
#   the default port 443.
#   Default is 443.
# [*gr_apache_24*]
#   Boolean to enable configuration parts for Apache 2.4 instead of 2.2
#   Default is false. (use Apache 2.2 config)
# [*gr_django_1_4_or_less*]
#   Set to true to use old Django settings style.
#   Default is false.
# [*gr_django_db_xxx*]
#   Django database settings. (engine|name|user|password|host|port)
#   Default is a local sqlite3 db.
# [*gr_enable_carbon_relay*]
#   Enable carbon relay.
#   Default is false.
# [*gr_relay_line_interface*]
#   Default is '0.0.0.0'
# [*gr_relay_line_port*]
#   Default is 2013.
# [*gr_relay_pickle_interface*]
#   Default is '0.0.0.0'
# [*gr_relay_pickle_port*]
#   Default is 2014.
# [*gr_relay_method*]
#   Default is 'rules'
# [*gr_relay_replication_factor*]
#   add redundancy by replicating every datapoint to more than one machine.
#   Default is 1.
# [*gr_relay_destinations*]
#   Array of backend carbons for relay.
#   Default  is [ '127.0.0.1:2004' ]
# [*gr_relay_max_queue_size*]
#   Default is 10000.
# [*gr_relay_use_flow_control*]
#   Default is 'True'
# [*gr_relay_rules*]
#   Relay rule set.
#   Default is
#   {
#   all       => { pattern      => '.*',
#                  destinations => [ '127.0.0.1:2004' ] },
#   'default' => { 'default'    => true,
#                  destinations => [ '127.0.0.1:2004:a' ] },
#   }
# [*gr_enable_carbon_aggregator*]
#   Enable the carbon aggregator daemon
#   Default is false.
# [*gr_aggregator_line_interface*]
#   Default is '0.0.0.0'
# [*gr_aggregator_line_port*]
#   Default is 2023.
# [*gr_aggregator_pickle_interface*]
#   Default is '0.0.0.0'
# [*gr_aggregator_pickle_port*]
#   Default is 2024.
# [*gr_aggregator_forward_all*]
#   Default is 'True'
# [*gr_aggregator_destinations*]
#   Array of backend carbons
#   Default is [ '127.0.0.1:2004' ]
# [*gr_aggregator_replication_factor*]
#   add redundancy by replicating every datapoint to more than one machine.
#   Default is 1.
# [*gr_aggregator_max_queue_size*]
#   Default is 10000
# [*gr_aggregator_use_flow_control*]
#   Default is 'True'
# [*gr_aggregator_max_intervals*]
#   Default is 5
# [*gr_aggregator_rules*]
#   Array of aggregation rules, as configuration file lines
#   Default is {
#    'carbon-class-mem' =>
#       carbon.all.<class>.memUsage (60) = sum carbon.<class>.*.memUsage',
#    'carbon-all-mem' =>
#       'carbon.all.memUsage (60) = sum carbon.*.*.memUsage',
#    }
# [*gr_amqp_enable*]
#   Set this to 'True' to enable the AMQP.
#   Default is 'False'.
# [*gr_amqp_verbose*]
#   Set this to 'True' to enable. Verbose means a line will be logged for
#   every metric received useful for testing.
#   Default is 'False'.
# [*gr_amqp_host*]
#   Self explaining.
#   Default is localhost.
# [*gr_amqp_port*]
#   Self explaining.
#   Default is 5672.
# [*gr_amqp_vhost*]
#   Virtual host of AMQP. Set the name without the slash, eg. 'graphite'.
#   Default is '/'.
# [*gr_amqp_user*]
#   Self explaining.
#   Default is guest.
# [*gr_amqp_password*]
#   Self explaining.
#   Default is guest.
# [*gr_amqp_exchange*]
#   Self explaining.
#   Default is graphite.
# [*gr_amqp_metric_name_in_body*]
#   Self explaining.
#   Default is 'False'.
# [*gr_memcache_hosts*]
#   Array of memcache hosts. e.g.: ['127.0.0.1:11211', '10.10.10.1:11211']
#   Defalut is undef
# [*secret_key*]
#   Secret used as salt for things like hashes, cookies, sessions etc.
#   Has to be the same on all nodes of a graphite cluster.
#   Default is UNSAFE_DEFAULT (CHANGE IT!)
# [*gr_cluster_enable*]
#   en/dis-able cluster configuration.   Default: false
# [*gr_cluster_servers*]
#   list of IP:port tuples for the servers in the cluster.  Default: "[]"
# [*gr_cluster_fetch_timeout*]
#    Timeout to fetch series data.   Default = 6
# [*gr_cluster_find_timeout*]
#    Timeout for metric find requests.   Default = 2.5
# [*gr_cluster_retry_delay*]
#    Time before retrying a failed remote webapp.  Default = 60
# [*gr_cluster_cache_duration*]
#    Time to cache remote metric find results.  Default = 300
# [*nginx_htpasswd*]
#   The user and salted SHA-1 (SSHA) password for Nginx authentication.
#   If set, Nginx will be configured to use HTTP Basic authentication with the
#   given user & password.
#   Default is undefined
# [*manage_ca_certificate*]
#   Used to determine to install ca-certificate or not. default = true
# [*gr_use_ldap*]
#   Turn ldap authentication on/off. Default = false
# [*gr_ldap_uri*]
#   Set ldap uri.  Default = ''
# [*gr_ldap_search_base*]
#   Set the ldap search base.  Default = ''
# [*gr_ldap_base_user*]
#   Set ldap base user.  Default = ''
# [*gr_ldap_base_pass*]
#   Set ldap password.  Default = ''
# [*gr_ldap_user_query*]
#   Set ldap user query.  Default = '(username=%s)'
# [*gr_use_remote_user_auth*]
#   Allow use of REMOTE_USER env variable within Django/Graphite.
#   Default is 'False' (String)
# [*gr_remote_user_header_name*]
#   Allows the use of a custom HTTP header, instead of the REMOTE_USER env
#   variable (mainly for nginx use) to tell Graphite a user is authenticated.
#   Useful when using an external auth handler with X-Accel-Redirect etc.
#   Example value - HTTP_X_REMOTE_USER

# === Examples
#
# class {'graphite':
#   gr_max_cache_size      => 256,
#   gr_enable_udp_listener => True,
#   gr_timezone            => 'Europe/Berlin'
# }
#
class graphite (
  $gr_user                      = '',
  $gr_max_cache_size            = inf,
  $gr_max_updates_per_second    = 500,
  $gr_max_creates_per_minute    = 50,
  $gr_carbon_metric_interval    = 60,
  $gr_line_receiver_interface   = '0.0.0.0',
  $gr_line_receiver_port        = 2003,
  $gr_enable_udp_listener       = 'False',
  $gr_udp_receiver_interface    = '0.0.0.0',
  $gr_udp_receiver_port         = 2003,
  $gr_pickle_receiver_interface = '0.0.0.0',
  $gr_pickle_receiver_port      = 2004,
  $gr_use_insecure_unpickler    = 'False',
  $gr_use_whitelist             = 'False',
  $gr_cache_query_interface     = '0.0.0.0',
  $gr_cache_query_port          = 7002,
  $gr_timezone                  = 'GMT',
  $gr_storage_schemas           = [
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
  ],
  $gr_storage_aggregation_rules  = {
    '00_min' => {
      pattern => '\.min$',
      factor => '0.1',
      method => 'min'
    },
    '01_max' => {
      pattern => '\.max$',
      factor => '0.1',
      method => 'max'
    },
    '02_sum' => {
      pattern => '\.count$',
      factor => '0.1',
      method => 'sum'
    },
    '99_default_avg' => {
      pattern => '.*',
      factor => '0.5',
      method => 'average'
    }
  },
  $gr_web_server                = 'apache',
  $gr_web_servername            = $::fqdn,
  $gr_web_cors_allow_from_all   = false,
  $gr_apache_port               = 80,
  $gr_apache_port_https         = 443,
  $gr_apache_24                 = false,
  $gr_django_1_4_or_less        = false,
  $gr_django_db_engine          = 'django.db.backends.sqlite3',
  $gr_django_db_name            = '/opt/graphite/storage/graphite.db',
  $gr_django_db_user            = '',
  $gr_django_db_password        = '',
  $gr_django_db_host            = '',
  $gr_django_db_port            = '',
  $gr_enable_carbon_relay       = false,
  $gr_relay_line_interface      = '0.0.0.0',
  $gr_relay_line_port           = 2013,
  $gr_relay_pickle_interface    = '0.0.0.0',
  $gr_relay_pickle_port         = 2014,
  $gr_relay_method              = 'rules',
  $gr_relay_replication_factor  = 1,
  $gr_relay_destinations        = [ '127.0.0.1:2004' ],
  $gr_relay_max_queue_size      = 10000,
  $gr_relay_use_flow_control    = 'True',
  $gr_relay_rules               = {
    all => {
      pattern      => '.*',
      destinations => [ '127.0.0.1:2004' ]
    },
    'default' => {
      'default'    => true,
      destinations => [ '127.0.0.1:2004:a' ]
    },
  },
  $gr_enable_carbon_aggregator  = false,
  $gr_aggregator_line_interface = '0.0.0.0',
  $gr_aggregator_line_port      = 2023,
  $gr_aggregator_pickle_interface = '0.0.0.0',
  $gr_aggregator_pickle_port    = 2024,
  $gr_aggregator_forward_all    = 'True',
  $gr_aggregator_destinations   = [ '127.0.0.1:2004' ],
  $gr_aggregator_replication_factor = 1,
  $gr_aggregator_max_queue_size = 10000,
  $gr_aggregator_use_flow_control = 'True',
  $gr_aggregator_max_intervals  = 5,
  $gr_aggregator_rules          = {
    'carbon-class-mem' => 'carbon.all.<class>.memUsage (60) = sum carbon.<class>.*.memUsage',
    'carbon-all-mem'   => 'carbon.all.memUsage (60) = sum carbon.*.*.memUsage',
    },
  $gr_amqp_enable               = 'False',
  $gr_amqp_verbose              = 'False',
  $gr_amqp_host                 = 'localhost',
  $gr_amqp_port                 = 5672,
  $gr_amqp_vhost                = '/',
  $gr_amqp_user                 = 'guest',
  $gr_amqp_password             = 'guest',
  $gr_amqp_exchange             = 'graphite',
  $gr_amqp_metric_name_in_body  = 'False',
  $gr_memcache_hosts            = undef,
  $secret_key                   = 'UNSAFE_DEFAULT',
  $gr_cluster_enable            = false,
  $gr_cluster_servers           = '[]',
  $gr_cluster_fetch_timeout     = 6,
  $gr_cluster_find_timeout      = 2.5,
  $gr_cluster_retry_delay       = 60,
  $gr_cluster_cache_duration    = 300,
  $nginx_htpasswd               = undef,
  $manage_ca_certificate        = true,
  $gr_use_ldap                  = false,
  $gr_ldap_uri                  = '',
  $gr_ldap_search_base          = '',
  $gr_ldap_base_user            = '',
  $gr_ldap_base_pass            = '',
  $gr_ldap_user_query           = '(username=%s)',
  $gr_use_remote_user_auth      = 'False',
  $gr_remote_user_header_name   = undef,
  $gr_line_receiver_port_b      = '2103',
  $gr_pickle_receiver_port_b    = '2104',
  $gr_cache_query_port_b        = '7102'
) {
  # Validation of input variables.
  # TODO - validate all the things
  validate_string($gr_use_remote_user_auth)

  # The anchor resources allow the end user to establish relationships
  # to the "main" class and preserve the relationship to the
  # implementation classes through a transitive relationship to
  # the composite class.
  # https://projects.puppetlabs.com/projects/puppet/wiki/Anchor_Pattern
  anchor { 'graphite::begin':}->
  class { 'graphite::install':}~>
  class { 'graphite::config':}->
  anchor { 'graphite::end':}

}
