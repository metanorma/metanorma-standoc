Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

eval_gemfile("Gemfile.devel") rescue nil

gem "metanorma-plugin-lutaml", github: "metanorma/metanorma-plugin-lutaml", branch: "feature/unitsml_liquid_filters"
