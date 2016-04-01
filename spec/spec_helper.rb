if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'coveralls'
  
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  #Coveralls.wear!
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/.vendor/'
  end
end

RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end

require 'puppetlabs_spec_helper/module_spec_helper'
