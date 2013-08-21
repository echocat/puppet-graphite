# == Class: graphite
#
# This class installs and configures graphite/carbon/whisper.
#
# === Parameters
#
# [*gr_user*]
#   The user who runs graphite. If this is empty carbon runs as the user that invokes it.
#   Default is empty.
# [*gr_max_cache_size*]
#   Limit the size of the cache to avoid swapping or becoming CPU bound. Use the value "inf" (infinity) for an unlimited cache size.
#   Default is inf.
# [*gr_max_updates_per_second*]
#   Limits the number of whisper update_many() calls per second, which effectively means the number of write requests sent to the disk.
#   Default is 500.
# [*gr_max_creates_per_minute*]
#   Softly limits the number of whisper files that get created each minute.
#   Default is 50.
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
# [*gr_cache_query_interface*]
#   Interface to send cache queries to.
#   Default is 0.0.0.0
# [*gr_cache_query_port*]
#   Self explaining.
#   Default is 7002.
# [*gr_timezone*]
#   Timezone for graphite to be used.
#   Default is GMT.
# [*gr_apache_port*]
#   The port to run apache on if you have an existing web server on the default
#   port 80.
#   Default is 80.
# [*gr_default_storage_retention*]
#   The default retention policy to be used in Graphite's storage-schemas.conf.
#   Default is '1s:30m,60s:24h,300s:730d'.
#   This means that all data is stored for 2 years with a precision of
#     1 seconds for last 30 minutes
#     60 seconds for last day
#     5 minutes for last 2 years
#


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
  $gr_line_receiver_interface   = '0.0.0.0',
  $gr_line_receiver_port        = 2003,
  $gr_enable_udp_listener       = False,
  $gr_udp_receiver_interface    = '0.0.0.0',
  $gr_udp_receiver_port         = 2003,
  $gr_pickle_receiver_interface = '0.0.0.0',
  $gr_pickle_receiver_port      = 2004,
  $gr_use_insecure_unpickler    = False,
  $gr_cache_query_interface     = '0.0.0.0',
  $gr_cache_query_port          = 7002,
  $gr_timezone                  = 'GMT',
  $gr_apache_port               = 80,
  $gr_apache_port_https         = 443,
  $gr_default_storage_retention = '1s:30m,60s:24h,300s:730d'
) {

  class { 'graphite::install': notify => Class['graphite::config'] }

  class { 'graphite::config':	require => Class['graphite::install'] }

  # Allow the end user to establish relationships to the "main" class
  # and preserve the relationship to the implementation classes through
  # a transitive relationship to the composite class.
  anchor { 'graphite::begin': before => Class['graphite::install'] }
  anchor { 'graphite::end':  require => Class['graphite::config'] }
}
