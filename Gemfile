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
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"
gem "metanorma-mirror", github: "metanorma/metanorma-mirror", branch: "main" # flip to version on release
# isodoc: relaton-cli 3.0.0.pre allowance (#824) merged after the 3.7.2 release — main until the next release
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "relaton-bib", "~> 2.2.0.pre.alpha.1"
# relaton 3.0.0.pre.alpha.1 from rubygems still calls the removed
# pubid base_identifier (fixed on relaton main as db9840bdf, unreleased);
# same declared version, so the git pin satisfies relaton-cli's exact
# '= 3.0.0.pre.alpha.1' — revert to the released gem at the next
# relaton prerelease/final.
gem "relaton", github: "relaton/relaton", branch: "main"
gem "pubid", github: "pubid/pubid", branch: "main"

eval_gemfile("Gemfile.devel") rescue nil
