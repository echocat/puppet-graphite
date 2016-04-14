require 'spec_helper'

describe 'graphite::config_apache', :type => 'class' do

  shared_context 'all platforms' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('graphite::params') }
  end

  shared_context 'RedHat supported platforms' do
    it { is_expected.to contain_package('httpd').only_with({ :name => 'httpd', :ensure => 'installed' }) }
  end

  shared_context 'Debian supported platforms' do
    it { is_expected.to contain_package('apache2').only_with({ :name => 'apache2', :ensure => 'installed' }) }
  end

  context 'Unsupported OS' do
    let(:facts) {{ :osfamily => 'unsupported', :operatingsystem => 'UnknownOS' }}
    it { is_expected.to raise_error(Puppet::Error, /unsupported os,.+\./ )}
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      let :pre_condition do
        'include ::graphite'
      end

      it_behaves_like 'all platforms'

      case facts[:osfamily]
      when 'Debian' then
        it_behaves_like 'Debian supported platforms'
      when 'RedHat' then
        it_behaves_like 'RedHat supported platforms'
      else
        it { is_expected.to raise_error(Puppet::Error, /unsupported os,.+\./ )}
      end

    end

  end

end