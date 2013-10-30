ENV["RAILS_ENV"] ||= "test"

require 'simplecov'
SimpleCov.start do
  add_filter "/config/"
  add_filter "/lib/"
  add_filter "/spec/"
end

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl_rails'
require 'timecop'

ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), "../")

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
end

# Generate a SQRL callback URI.
def sqrl_uri(nut, sqrlver = 1, sqrlkey = nil)
  if defined? squarrel
    result = squarrel.sqrl_url(protocol: :sqrl, nut: nut)
  else
    result = "sqrl://example.com/sqrl/login?nut=#{nut}"
  end

  result += "&sqrlver=#{sqrlver}" unless sqrlver.nil?
  result += "&sqrlkey=#{sqrlkey}" unless sqrlkey.nil?
end
