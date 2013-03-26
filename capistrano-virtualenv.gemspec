# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-virtualenv/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yamashita Yuu"]
  gem.email         = ["yamashita@geishatokyo.com"]
  gem.description   = %q{a capistrano recipe to deploy python apps with virtualenv.}
  gem.summary       = %q{a capistrano recipe to deploy python apps with virtualenv.}
  gem.homepage      = "https://github.com/yyuu/capistrano-virtualenv"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-virtualenv"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Virtualenv::VERSION

  gem.add_dependency("capistrano")
  gem.add_dependency("capistrano-platform-resources", ">= 0.1.0")
  gem.add_development_dependency("net-scp", "~> 1.0.4")
  gem.add_development_dependency("net-ssh", "~> 2.2.2")
  gem.add_development_dependency("vagrant", "~> 1.0.6")
end
