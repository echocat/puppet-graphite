require 'spec_helper'

describe 'graphite::config', :type => 'class' do

  shared_context 'Unsupported OS' do
    it { should raise_error(Puppet::Error,/unsupported os,.+\./ )}
  end

  shared_context 'Debian unsupported platforms' do
    it { should raise_error(Puppet::Error,/Unsupported Debian release/) }
  end

  shared_context 'RedHat unsupported platforms' do
    it { should raise_error(Puppet::Error,/Unsupported RedHat release/) }
  end

  shared_context 'supported platforms' do
    it { should contain_class('graphite::params') }
    it { should contain_file('/opt/graphite/bin/carbon-logrotate.sh')}
  end

  shared_context 'RedHat supported platforms' do
  end

  shared_context 'RedHat 6 platforms' do
  end

  shared_context 'RedHat 7 platforms' do
  end

  shared_context 'Debian supported platforms' do
  end

  # Loop through various contexts
  [ { :osfamily => 'Debian', :lsbdistcodename => 'capybara', :operatingsystem => 'Debian' },
    { :osfamily => 'Debian', :lsbdistcodename => 'squeeze',  :operatingsystem => 'Debian' },
    { :osfamily => 'Debian', :lsbdistcodename => 'trusty',   :operatingsystem => 'Debian' },
    { :osfamily => 'FreeBSD', :operatingsystemrelease => '8.4-RELEASE-p27', :operatingsystem => 'FreeBSD' },
    { :osfamily => 'RedHat', :operatingsystemrelease => '5.0', :operatingsystem => 'CentOS' },
    { :osfamily => 'RedHat', :operatingsystemrelease => '6.6', :operatingsystem => 'CentOS' },
    { :osfamily => 'RedHat', :operatingsystemrelease => '7.1', :operatingsystem => 'CentOS' },
  ].each do |myfacts|

    context 'OS %s %s' % myfacts.values do
      let :facts do myfacts end
      let :pre_condition do 'include ::graphite' end

      case myfacts[:osfamily]
      when 'Debian' then
        case myfacts[:lsbdistcodename]
        when 'capybara' then
          it_behaves_like 'Debian unsupported platforms'
        else
          it_behaves_like 'supported platforms'
          it_behaves_like 'Debian supported platforms'

        end
      when 'RedHat' then
        case myfacts[:operatingsystemrelease]
        when /^[6-7]/ then
          it_behaves_like 'supported platforms'
          it_behaves_like 'RedHat supported platforms'
          case myfacts[:operatingsystemrelease]
          when /^6/ then
            it_behaves_like 'RedHat 6 platforms'
          when /^7/ then
            it_behaves_like 'RedHat 7 platforms'
          end

        else
          it_behaves_like 'RedHat unsupported platforms'
        end
      else
        it_behaves_like 'Unsupported OS'
      end
    end
  end
end
