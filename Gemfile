Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

# Stopgap: lutaml 0.11.x removed lib/lutaml/xmi.rb, which metanorma-plugin-lutaml
# 0.7.x still `require`s. Hold lutaml at 0.10.x until plugin-lutaml follows the
# file to its new home. Remove once resolved:
# https://github.com/metanorma/metanorma-plugin-lutaml/issues/292
gem "lutaml", "< 0.11"

eval_gemfile("Gemfile.devel") rescue nil
