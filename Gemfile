source 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_GEM_VERSION') ? "#{ENV['PUPPET_GEM_VERSION']}" : ['>= 3.3']
facterversion = ENV.key?('FACTER_GEM_VERSION') ? "#{ENV['FACTER_GEM_VERSION']}" : ['>= 1.7']
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 0.1.0'
gem 'puppet-lint', '>= 0.3.2'
gem 'facter', facterversion
gem 'rspec', '< 3.2.0'
# rubi <1.9 versus rake 11.0.0 workaround
gem 'rake', '< 11.0.0'
