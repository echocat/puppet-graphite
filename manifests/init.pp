class graphite (
	$gr_user = "",
	$gr_max_cache_size = inf,
	$gr_max_updates_per_second = 500,
	$gr_max_creates_per_minute = 50,
	$gr_line_receiver_interface = '0.0.0.0',
	$gr_line_receiver_port = 2003,
	$gr_enable_udp_listener = False,
	$gr_udp_receiver_interface = '0.0.0.0',
	$gr_udp_receiver_port = 2003,
	$gr_pickle_receiver_interface = "0.0.0.0",
	$gr_pickle_receiver_port = 2004,
	$gr_use_insecure_unpickler = False,
	$gr_cache_query_interface = '0.0.0.0',
	$gr_cache_query_port = 7002,
	$gr_timezone = 'Europe/Berlin'
) {

	class { 'graphite::install': notify => Class['graphite::config'] }

	class { 'graphite::config':
		gr_user                      => $gr_user,
		gr_max_cache_size            => $gr_max_cache_size,
		gr_max_updates_per_second    => $gr_max_updates_per_second,
		gr_max_creates_per_minute    => $gr_max_creates_per_minute,
		gr_line_receiver_interface   => $gr_line_receiver_interface,
		gr_line_receiver_port        => $gr_line_receiver_port,
		gr_enable_udp_listener       => $gr_enable_udp_listener,
		gr_udp_receiver_interface    => $gr_udp_receiver_interface,
		gr_udp_receiver_port         => $gr_udp_receiver_port,
		gr_pickle_receiver_interface => $gr_pickle_receiver_interface,
		gr_pickle_receiver_port      => $gr_pickle_receiver_port,
		gr_use_insecure_unpickler    => $gr_use_insecure_unpickler,
		gr_cache_query_interface     => $gr_cache_query_interface,
		gr_cache_query_port          => $gr_cache_query_port,
		gr_timezone                  => $gr_timezone,
		require => Class['graphite::install']
	}

      # Allow the end user to establish relationships to the "main" class
      # and preserve the relationship to the implementation classes through
      # a transitive relationship to the composite class.
      anchor { 'graphite::begin': before => Class['graphite::install'] }
      anchor { 'graphite::end': require => Class['graphite::config'] }
}
