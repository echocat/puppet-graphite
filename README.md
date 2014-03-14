# Module graphite

This module installs and makes basic configs for graphite, with carbon and whisper.

# Tested on
RHEL/CentOS/Scientific 6+
Debian 6+
Ubunutu 10.04 and newer

# Requirements

Configure conf files as you need:
  
Only if you want to use carbon-link clusters or ldap you should edit:  
templates/opt/graphite/webapp/graphite/local_settings.py.erb

### Modules needed:

stdlib by puppetlabs

### Software versions needed:
facter > 1.6.2
puppet > 2.6.2

On Redhat distributions you need the EPEL or RPMforge repository, because Graphite needs packages, which are not part of the default repos.

# Parameters

The descriptions are short and their are more variables to tweak your graphite if needed.
For further information take a look at the file templates/opt/graphite/conf/carbon.conf.erb

<table>
  <tr>
  	<th>Parameter</th><th>Default</th><th>Description</th>
  </tr>
  <tr>
    <td>gr_user</td><td> its empty </td><td>The user who runs graphite. If this is empty carbon runs as the user that invokes it.</td>
  </tr>
  <tr>
    <td>gr_max_cache_size</td><td>inf</td><td>Limit the size of the cache to avoid swapping or becoming CPU bound. Use the value "inf" (infinity) for an unlimited cache size.</td>
  </tr>
  <tr>
    <td>gr_max_updates_per_second</td><td>500</td><td>Limits the number of whisper update_many() calls per second, which effectively means the number of write requests sent to the disk.</td>
  </tr>
  <tr>
    <td>gr_max_creates_per_minute</td><td>50</td><td>Softly limits the number of whisper files that get created each minute.</td>
  </tr><td>gr_carbon_metric_interval</td><td>60</td><td>Set the interval between sending internal performance metrics; affects all carbon daemons.</td>
  </tr>
  <tr>
    <td>gr_line_receiver_interface</td><td>0.0.0.0</td><td>Interface the line receiver listens</td>
  </tr>
  <tr>
    <td>gr_line_receiver_port</td><td>2003</td><td>Port of line receiver</td>
  </tr>
  <tr>
    <td>gr_enable_udp_listener</td><td>False</td><td>Set this to True to enable the UDP listener.</td>
  </tr>
  <tr>
    <td>gr_udp_receiver_interface</td><td>0.0.0.0</td><td>Its clear, isnt it?</td>
  </tr>
  <tr>
    <td>gr_udp_receiver_port</td><td>2003</td><td>Self explaining</td>
  </tr>
  <tr>
    <td>gr_pickle_receiver_interface</td><td>0.0.0.0</td><td>Pickle is a special receiver who handle tuples of data.</td>
  </tr>
  <tr>
    <td>gr_pickle_receiver_port</td><td>2004</td><td>Self explaining</td>
  </tr>
  <tr>
    <td>gr_use_insecure_unpickler</td><td>False</td><td>Set this to True to revert to the old-fashioned insecure unpickler.</td>
  </tr>
  <tr>
    <td>gr_cache_query_interface</td><td>0.0.0.0</td><td>Interface to send cache queries to.</td>
  </tr>
  <tr>
    <td>gr_cache_query_port</td><td>7002</td><td>Self explaining.</td>
  </tr>
  <tr>
    <td>gr_timezone</td><td>GMT</td><td>Timezone for graphite to be used.</td>
  </tr>
  <tr>
    <td>gr_storage_schemas</td><td><pre>[
  {
    name       => "default",
    pattern    => ".*",
    retentions => "1s:30m,1m:1d,5m:2y"
  }
]</pre></td><td>The storage schemas.</td>
  </tr>
  <tr><td>gr_storage_aggregation_rules</td><td><pre>{
     '00_min'         => { pattern => '\.min$',   factor => '0.1', method => 'min' },
     '01_max'         => { pattern => '\.max$',   factor => '0.1', method => 'max' },
     '02_sum'         => { pattern => '\.count$', factor => '0.1', method => 'sum' },
     '99_default_avg' => { pattern => '.*',       factor => '0.5', method => 'average'}
   }</pre></td><td>The storage aggregation rules</td>
  </tr>
  <tr>
    <td>gr_web_server</td><td>apache</td><td>The web server to use. Valid values are 'apache' and 'nginx'. 'nginx' is only supported on Debian-like systems.</td>
  </tr>
  <tr>
    <td>gr_web_servername</td><td>FQDN</td><td>Virtualhostname of Graphite webgui.</td>
  </tr>
  <tr>
    <td>gr_web_cors_allow_from_all</td><td>false</td><td>Include CORS Headers for all hosts (*) in web server config.</td>
  </tr>
  <tr>
    <td>gr_apache_port</td><td>80</td><td>The HTTP port apache will use.</td>
  </tr>
  <tr>
    <td>gr_apache_port_https</td><td>443</td><td>The HTTPS port apache will use.</td>
  </tr>
  <tr>
    <td>gr_django_1_4_or_less</td><td>false</td><td>Django settings style.</td>
  </tr>
  <tr>
    <td>gr_django_db_xxx</td><td>sqlite3 settings</td><td>Django database settings. (engine|name|user|password|host|port)</td>
  </tr>
  <tr>
  <td>gr_enable_carbon_aggregator</td><td>false</td><td>Enable the carbon aggregator daemon</td>
</tr>
<tr>
  <td>gr_aggregator_line_interface</td><td>'0.0.0.0'</td><td>address for line interface to listen on </td>
</tr>
<tr>
  <td>gr_aggregator_line_port</td><td>2023</td><td>TCP port for line interface to listen on</td>
</tr>
<tr>
  <td>gr_aggregator_pickle_interface</td><td>'0.0.0.0'</td><td>address for pickle interface</td>
</tr>
<tr>
  <td>gr_aggregator_pickle_port</td><td>2024</td><td>pickle port</td>
</tr>
<tr>
  <td>gr_aggregator_forward_all</td><td>'True'</td><td>Forward all metrics to the destination(s)</td>
</tr>
  <tr><td>gr_aggregator_destinations</td><td><pre>[ '127.0.0.1:2004' ]</pre></td><td>array of backend carbons</td>
</tr>
<tr>
  <td>gr_aggregator_max_queue_size</td><td>10000</td><td>maximum queue size</td>
</tr>
<tr>
  <td>gr_aggregator_use_flow_control</td><td>'True"</td><td>Enable flow control</td>
</tr>
<tr>
  <td>gr_aggregator_max_intervals</td><td>5</td><td>maximum # intervals to keep around</td></tr>
<tr>
  <td>gr_aggregator_rules</td><td><pre>{
    'carbon-class-mem'  => 'carbon.all.<class>.memUsage (60) = sum carbon.<class>.*.memUsage',
    'carbon-all-mem'    => 'carbon.all.memUsage (60) = sum carbon.*.*.memUsage',
    }</pre></td><td>array of carbon aggregation rules</td>
</tr>
<tr><td>gr_memcache_enable</td><td>false</td><td>Enable / Disable memcache usage</td>
  </tr>
  <tr><td>gr_memcache_hosts</td><td><pre>"['127.0.0.1:11211']"</pre></td><td>List of memcache hosts to use.</td>
  </tr>
  <tr>
    <td>secret_key</td><td>UNSAFE_DEFAULT</td><td>CHANGE IT! Secret used as salt for things like hashes, cookies, sessions etc. Has to be the same on all nodes of a graphite cluster.</td>
  </tr>
  <tr>
    <td>nginx_htpasswd</td><td>undef</td><td>The user and salted SHA-1 (SSHA) password for Nginx authentication. If set, Nginx will be configured to use HTTP Basic authentication with the given user & password.</td>
  </tr>
  <tr>
    <td>manage_ca_certificate</td><td>true</td><td>Used to determine if the module should install ca-certificate on debian machines during the initial installation.</td>
  </tr>
</table>

# Sample usage:

### Out of the box graphite installation
<pre>
node "graphite.my.domain" {
	include graphite
}
</pre>

### Tuned graphite installation

<pre>

# This carbon cache will accept TCP and UDP datas and
# the cachesize is limited to 256mb
node "graphite.my.domain" {
	class {'graphite':
		gr_max_cache_size => 256,
		gr_enable_udp_listener => True
	}
}
</pre>

### Using MySQL Backend and Aggregator

<pre>

node "graphite.my.domain" {
  class { 'graphite':
    gr_django_db_engine   => 'django.db.backends.mysql',
    gr_django_db_name     => 'graphite',
    gr_django_db_user     => 'graphite',
    gr_django_db_password => 'SECRET123',
    gr_django_db_host     => 'mysql.my.domain',
    gr_django_db_port     => 3306,
    gr_enable_carbon_aggregator => true,
    secret_key => 'ABCD1234',
  }
}
</pre>

## Optional

### Move Apache to alternative ports:

The default puppet set up won't work if you have an existing web server in
place. In my case this was Nginx. For me moving apache off to another port was
good enough. To allow this you do

<pre>

  # Move apache to alternate HTTP/HTTPS ports:
node "graphite.my.domain" {
    class {'graphite':
        gr_apache_port => 2080,
        gr_apache_port_https => 2443,
    }
}

</pre>
