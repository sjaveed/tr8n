$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tr8n/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tr8n"
  s.version     = Tr8n::VERSION
  s.authors     = ["Michael Berkovich"]
  s.email       = ["theiceberk@gmail.com"]
  s.homepage    = "https://github.com/sjaveed/tr8n"
  s.summary     = "Crowd-sourced translation engine for Rails."
  s.description = "Crowd-sourced translation and localization engine for Rails."

  s.files         = `git ls-files`.split("\n") - Dir.glob("app/javascripts/**/*")
#   s.test_files    = `git ls-files -- {test,local,spec,features}/*`.split("\n")
  s.extra_rdoc_files = ['README.md']
  s.require_paths = ['lib']

  s.licenses = ['MIT']
  
  s.add_dependency "rails", '~> 3.2.3'
  s.add_dependency 'will_filter', '~> 3.1.10'
  s.add_dependency 'faraday', '>= 0'
  s.add_dependency 'liquid', '~> 2.5.3'
  s.add_dependency 'aasm'

end
