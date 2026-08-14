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

# TEMPORARY: cross-PR branch pins so CI can resolve the in-flight pubid-2 /
# relaton-bib 2.2 / metanorma-document 0.5 chain. Revert each to its
# released line once the corresponding PR merges.
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "feat/model-validation-l1-declarations"
gem "isodoc", github: "metanorma/isodoc", branch: "rt-pubid-2-migration"
gem "relaton-bib", "~> 2.2.0.pre.alpha.1"
gem "pubid", github: "pubid/pubid", branch: "main"

eval_gemfile("Gemfile.devel") rescue nil
