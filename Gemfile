Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }
gem "metanorma-plugin-lutaml", git: "git@github.com:metanorma/metanorma-plugin-lutaml.git", branch: "feature/lutaml_figure-support-multiply-nested-macroses-datamodel"

gemspec

if File.exist? 'Gemfile.devel'
  eval File.read('Gemfile.devel'), nil, 'Gemfile.devel' # rubocop:disable Security/Eval
end
