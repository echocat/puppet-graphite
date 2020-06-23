require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

# Install Puppet
run_puppet_install_helper
install_module_dependencies
install_module

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation
end
