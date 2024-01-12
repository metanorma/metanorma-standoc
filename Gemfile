Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gem "relaton-index", github: "alexeymorozov/relaton-index", branch: "windows-eaccess"
gemspec

eval_gemfile("Gemfile.devel") rescue nil
