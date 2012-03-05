# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "codger/version"

Gem::Specification.new do |s|
  s.name        = "codger"
  s.version     = Codger::VERSION
  s.authors     = ["Jacob Williams"]
  s.email       = ["jacobaw@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Manages invocation of code generators.}
  s.description = %q{Manages invocation of code generators.}

  s.rubyforge_project = "codger"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency 'activesupport', '~> 3.2.1'
  s.add_runtime_dependency 'deep_merge', '~> 1.0.0'
  s.add_runtime_dependency 'git', '~> 1.2.5'
  s.add_runtime_dependency 'thor', '~> 0.14.6'
end
