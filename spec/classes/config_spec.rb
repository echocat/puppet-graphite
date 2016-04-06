require 'spec_helper'

describe 'graphite::config', :type => 'class' do

  shared_context 'RedHat supported platforms' do
    it { is_expected.to contain_file('/opt/graphite/storage/whisper').with({
      'ensure' => 'directory', 'owner' => 'apache', 'group' => 'apache', 'mode' => '0755', }) }
    it { is_expected.to contain_file('/opt/graphite/storage/log/carbon-cache').with({
      'ensure' => 'directory', 'owner' => 'apache', 'group' => 'apache', 'mode' => '0755', }) }
    it { is_expected.to contain_file('/opt/graphite/storage/graphite.db').with({
      'ensure' => 'file', 'owner' => 'apache', 'group' => 'apache', 'mode' => '0644', }) }
    it { is_expected.to contain_file('/opt/graphite/webapp/graphite/local_settings.py').with({
      'ensure' => 'file', 'owner' => 'apache', 'group' => 'apache', 'mode' => '0644',
      'content' => /^CONF_DIR = '\/opt\/graphite\/conf'$/ }).that_requires('Package[httpd]') }
    it { is_expected.to contain_file('/opt/graphite/conf/graphite_wsgi.py').with({
      'ensure' => 'file', 'owner' => 'apache', 'group' => 'apache', 'mode' => '0644' }).that_requires('Package[httpd]') }
    it { is_expected.to contain_file('/opt/graphite/webapp/graphite/graphite_wsgi.py').with({
      'ensure' => 'link', 'target' => '/opt/graphite/conf/graphite_wsgi.py', 'require' => 'File[/opt/graphite/conf/graphite_wsgi.py]' }) }
    it { is_expected.to contain_service('carbon-cache').with({
        'ensure'     => 'running',
        'enable'     => 'true',
        'hasrestart' => 'true',
        'hasstatus'  => 'true',
        'provider'   => 'redhat',
        'require'    => 'File[/etc/init.d/carbon-cache]' }) }
  end

  shared_context 'RedHat 6 platforms' do
    it { is_expected.to contain_file('/etc/init.d/carbon-cache').with({
      'ensure'  => 'file',
      'content' => /^GRAPHITE_DIR="\/opt\/graphite"$/,
      'mode'    => '0750',
      'require' => 'File[/opt/graphite/conf/carbon.conf]',
      'notify'  => [] }) }
  end

  shared_context 'RedHat 7 platforms' do
    it { is_expected.to contain_exec('graphite-reload-systemd') }
    it { is_expected.to contain_file('/etc/init.d/carbon-cache').with({
      'ensure'  => 'file',
      'content' => /^GRAPHITE_DIR="\/opt\/graphite"$/,
      'mode'    => '0750',
      'require' => 'File[/opt/graphite/conf/carbon.conf]',
      'notify'  => '[Exec[graphite-reload-systemd]{:command=>"graphite-reload-systemd"}]' }) }
  end

  shared_context 'Debian supported platforms' do
    it { is_expected.to contain_file('/opt/graphite/storage/whisper').with({
      'ensure' => 'directory', 'owner' => 'www-data', 'group' => 'www-data', 'mode' => '0755', }) }
    it { is_expected.to contain_file('/opt/graphite/storage/log/carbon-cache').with({
      'ensure' => 'directory', 'owner' => 'www-data', 'group' => 'www-data', 'mode' => '0755', }) }
    it { is_expected.to contain_file('/opt/graphite/storage/graphite.db').with({
      'ensure' => 'file', 'owner' => 'www-data', 'group' => 'www-data', 'mode' => '0644', }) }
    it { is_expected.to contain_file('/opt/graphite/webapp/graphite/local_settings.py').with({
      'ensure' => 'file', 'owner' => 'www-data', 'group' => 'www-data', 'mode' => '0644',
      'content' => /^CONF_DIR = '\/opt\/graphite\/conf'$/ }).that_requires('Package[apache2]') }
    it { is_expected.to contain_file('/opt/graphite/conf/graphite_wsgi.py').with({
      'ensure' => 'file', 'owner' => 'www-data', 'group' => 'www-data', 'mode' => '0644' }).that_requires('Package[apache2]') }
    it { is_expected.to contain_file('/opt/graphite/webapp/graphite/graphite_wsgi.py').with({
      'ensure' => 'link', 'target' => '/opt/graphite/conf/graphite_wsgi.py', 'require' => 'File[/opt/graphite/conf/graphite_wsgi.py]' }) }
    it { is_expected.to contain_service('carbon-cache').only_with({
      'ensure'     => 'running',
      'enable'     => 'true',
      'hasrestart' => 'true',
      'hasstatus'  => 'true',
      'provider'   => nil,
      'require'    => 'File[/etc/init.d/carbon-cache]' }) }
    it { is_expected.to contain_file('/etc/init.d/carbon-cache').with({
      'ensure'  => 'file',
      'content' => /^GRAPHITE_DIR="\/opt\/graphite"$/,
      'mode'    => '0750',
      'require' => 'File[/opt/graphite/conf/carbon.conf]',
      'notify'  => [] }) }
  end


  context 'Unsupported OS' do
    let(:facts) {{ :osfamily => 'unsupported', :operatingsystem => 'UnknownOS' }}
    it { is_expected.to raise_error(Puppet::Error,/unsupported os,.+\./ )}
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      let :pre_condition do 
        'include ::graphite' 
      end
      
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('graphite::params') }
      it { is_expected.to contain_exec('Initial django db creation') }
      it { is_expected.to contain_class('graphite::config_apache') }     




#    file { '/etc/init.d/carbon-cache':
#      ensure  => file,
#      content => template("graphite/etc/init.d/${::osfamily}/carbon-cache.erb"),
#      mode    => '0750',
#      require => File[$carbon_conf_file],
#      notify  => $initscript_notify,
#    }




      # cron check
      it { is_expected.to contain_file('/opt/graphite/bin/carbon-logrotate.sh').with({
        'ensure' => 'file', 'mode' => '0544', 'content' => /^CARBON_LOGS_PATH="\/opt\/graphite\/storage\/log"$/ }) }    
      it { is_expected.to contain_cron('Rotate carbon logs').with({
        'command' => '/opt/graphite/bin/carbon-logrotate.sh',
        'hour'    => '3',
        'minute'  => '15',
        'require' => 'File[/opt/graphite/bin/carbon-logrotate.sh]',
        'user'    => 'root',}) }

      case facts[:osfamily]
      when 'Debian' then
        it_behaves_like 'Debian supported platforms'
      when 'RedHat' then
        it_behaves_like 'RedHat supported platforms'
        case facts[:operatingsystemrelease]
        when /^6/ then
          it_behaves_like 'RedHat 6 platforms'
        when /^7/ then
          it_behaves_like 'RedHat 7 platforms'
        else
          it { is_expected.to raise_error(Puppet::Error,/unsupported os,.+\./ )}
        end
      else
        it { is_expected.to raise_error(Puppet::Error,/unsupported os,.+\./ )}
      end
      
    end
  end

end
