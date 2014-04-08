## 2014-04-08 - 5.3.2 (Bugfix release)

#### Bugfixes:

- fix variablename for redhat releases in params.pp

## 2014-04-08 - 5.3.0 (Feature release)

#### Features:

- add support for Apache 2.4. See parameter `gr_apache_24`
- add `gr_use_whitelist` to set flag in carbon.conf. Default is False.
- add support for custom authentication using HTTP header
  See `gr_use_remote_user_auth` and `gr_remote_user_header_name`

#### Behavior changes:

- complete refactoring of install process, to solve dependency hell on redhat.
  Update process tested on CentOS 6.5 and Debian 7 Wheezy
- package `git` is not required anymore
- whisper, graphite-web, carbon are installed via pip now

## 2014-03-20 - 5.2.0 (Feature release)

#### Features:

- add support for LDAP config with `gr_use_ldap` and `gr_ldap_*` parameters
- `gr_web_server` can be set to 'apache', 'nginx', 'wsgionly' or 'none'

#### Behavior changes:

- remove `gr_memcache_enable`. Usage of memcached is configured/enabled if `gr_memcache_hosts` is set.
- `gr_memcache_hosts` changed from String to Array

#### Bugfixes:

- install txamqp correct on Debian

## 2014-03-17 - 5.1.1 (Bugfix release)

- allow Redhat based systems to use a different apache port correctly
- parameterize the install of ca-certificate on Debian distributions
- enable mod_headers on Debian apache if CORS is enabled
- fix install of txamqp for Debian 7.4
- some whitespace reformating

## 2014-01-27 - 5.1.0 (Feature release)

- add replication factor support
- added controls for handling cluster configuration in the web application

## 2014-01-10 - 5.0.0 (Major release)
  !!! Be aware that this module overwrites
  !!! carbon-aggregator and memcached configs now.
- allow to configure carbon aggregator
- allow to set vhost name web gui
- allow to configure memcached

## 2013-12-11 - 4.0.0 (Major release)

- implementation of carbon-relay configuration

## 2013-08-28 - 3.0.1 (Bugfix release)

- complet refactoring to support graphit 0.9.12
- add support for dynamic storage schemas
- add support for django version  > 1.4
- use mod_wsgi instead of mod_python
- fix some dependency issues

## 2013-03-30 - 2.4.1

- new parameters to set listen port for webui
- download sources with curl instead of wget on redhat
- refactoring, so variables are used in class scope
- add Rdoc documentation for puppet doc
- refactoring to match http://docs.puppetlabs.com/guides/style_guide.html
- some minor fixes

## 2012-12-13 - 2.3.0

- add cron to logrotate carbons logs

## 2012-12-08 - 2.2.0

- add parameter to set timezone of dashboard

## 2012-11-02 - 2.1.0

- optimize LSB configs in init script
- fix on djangodb creation

## 2012-10-24 - 2.0.0

- add parameter to graphite class to allow tweaking of carbon.conf
- rewrite README

## 2012-09-14 - 1.1.0

- minor fixes for debian

## 2012-09-06 - 1.0.0

- set path for exec statements

## 2012-08-16 - 0.1.1

- update README
- add package MySQL-python on rhel or MySQL support

## 2012-08-09 - 0.1.0

- first commit

