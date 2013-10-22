$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "squarrel/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "squarrel"
  s.version     = Squarrel::VERSION
  s.authors     = ["Nathan Clark"]
  s.email       = ["Nathan.Clark@tokenshift.com"]
  s.homepage    = "https://github.com/tokenshift/squarrel"
  s.summary     = "SQRL authentication for Rails."
  s.description = "Secure, multi-device authentication plugin for Ruby on Rails applications."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "timecop"
  s.add_development_dependency "simplecov"

  s.add_runtime_dependency "rbnacl"
end
