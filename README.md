# Module graphite

This module installs and makes basic configs for graphite, with carbon and whisper.
It support RHEL/CentOS 6+ and Debian 6+ Ubunutu 10.04 and newer.

@author: Daniel Werdermann / dwerdermann@web.de

#  Requirements:

Configure conf files as you need: 

templates/opt/graphite/conf/carbon.conf.erb
templates/opt/graphite/conf/storage-schemas.conf.erb
templates/opt/graphite/webapp/graphite/local_settings.py.erb

# Sample usage:
<pre>
node "graphite.my.domain" {
        include graphite
}
</pre>
