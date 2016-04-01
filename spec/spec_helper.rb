require 'puppetlabs_spec_helper/module_spec_helper'

# for code coverage

if ENV['COVERAGE'] == 'yes'
  require 'coveralls'
  Coveralls.wear!
end

RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end