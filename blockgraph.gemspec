# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "blockgraph/version"

Gem::Specification.new do |spec|
  spec.name          = "blockgraph"
  spec.version       = BlockGraph::VERSION
  spec.authors       = ["Jun Okumura"]
  spec.email         = ["okumura@haw.co.jp"]

  spec.summary       = %q{A tool for import Bitcoin blockchain data into neo4j database.}
  spec.description   = %q{A tool for import Bitcoin blockchain data into neo4j database.}
  spec.homepage      = "https://github.com/haw-itn/blockgraph.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "neo4j", "~> 9.1.4"
  spec.add_development_dependency "neo4j-rake_tasks"
  spec.add_development_dependency "bitcoinrb", "~> 0.1.6"
  spec.add_development_dependency "thor"
  spec.add_development_dependency "daemon-spawn"
  spec.add_development_dependency "activesupport", "~> 5.1.6"
  spec.add_development_dependency "octorelease"
  spec.add_development_dependency "parallel", "~> 1.12.1"
end
