node default {
  package {
    "ruby-json" :
    ensure => 'installed',
  }

  # change apache ports for vagrant
  # if required (defaults to 80/443)
  class { 'graphite':
    gr_apache_port               => 80,
    gr_apache_port_https         => 443
  }

  # epel is skipped over on non-redhat based 
  # distributions
  include epel

  include graphite
}
