node default {
  package {
    "ruby-json" :
    ensure => 'installed',
  }

  # epel is skipped over on non-redhat based 
  # distributions
  include epel

  include graphite
}
