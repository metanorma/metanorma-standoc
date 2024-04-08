# coding: utf-8

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma/standoc/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-standoc"
  spec.version       = Metanorma::Standoc::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "metanorma-standoc realises standards following the Metanorma standoc model"
  spec.description   = <<~DESCRIPTION
    metanorma-standoc realises standards following the Metanorma standoc model

    This gem is in active development.
  DESCRIPTION

  spec.homepage      = "https://github.com/metanorma/metanorma-standoc"
  spec.license       = "BSD-2-Clause"

  spec.bindir        = "bin"
  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|bin|.github)/}) \
    || f.match(%r{Rakefile|bin/rspec})
  end
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.add_dependency "addressable", "~> 2.8.0"
  spec.add_dependency "asciidoctor", "~> 2.0.0"
  spec.add_dependency "crass", "~> 1.0.0"
  spec.add_dependency "iev", "~> 0.3.0"
  spec.add_dependency "isodoc", "~> 2.10.0"
  spec.add_dependency "metanorma", ">= 1.6.0"
  spec.add_dependency "metanorma-plugin-datastruct", "~> 0.3.0"
  spec.add_dependency "metanorma-plugin-glossarist", "~> 0.2.0"
  spec.add_dependency "metanorma-plugin-lutaml", "~> 0.5.0"
  spec.add_dependency "ruby-jing"
  # relaton-cli not just relaton, to avoid circular reference in metanorma
  spec.add_dependency "asciimath2unitsml", "~> 0.4.0"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "pngcheck"
  spec.add_dependency "relaton-cli", "~> 1.18.0"
  spec.add_dependency "relaton-iev", "~> 1.2.0"
  spec.add_dependency "unicode2latex", "~> 0.0.1"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "guard", "~> 2.14"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rubocop", "~> 1.5.2"
  spec.add_development_dependency "sassc", "2.4.0"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "vcr", "~> 6.1.0"
  spec.add_development_dependency "webmock"
  # spec.metadata["rubygems_mfa_required"] = "true"
end
