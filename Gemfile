Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec
gem "metanorma-mirror", "~> 1.0"

# Stopgap: lutaml 0.11.x removed lib/lutaml/xmi.rb, which metanorma-plugin-lutaml
# 0.7.x still `require`s. Hold lutaml at 0.10.x until plugin-lutaml follows the
# file to its new home. Remove once resolved:
# https://github.com/metanorma/metanorma-plugin-lutaml/issues/292
gem "lutaml", "< 0.11"

# Stopgap: lutaml-lml 0.3.7 turned the gem into a stub alias forwarding
# require "lutaml/lml" into the lutaml gem — which only carries that file
# from 0.11.8, inside the cap above. Hold the alias down until the stub
# ships its lutaml >= 0.11.8 floor.
gem "lutaml-lml", "< 0.3.7"

# Pin: update units (metanorma-document#122); return to "~> 0.5" once it is released.
gem "metanorma-document", github: "metanorma/metanorma-document",
                          ref: "b2d7d50b4b1dbb85daa02387dcfb60a745960185"
gem "isodoc", "~> 3.7"
# relaton 3.0.0.pre.alpha.1 from rubygems called the removed pubid
# base_identifier; the fix (db9840bdf) shipped in the 3.0.0.pre.alpha.4
# release. Prefer the released gem over a git pin: relaton main has since
# moved to lutaml-store ~> 0.3, which conflicts with glossarist 2.14's
# lutaml-store ~> 0.2.0 and makes this bundle unresolvable.
gem "parsanol", "~> 1.3.123"
gem "relaton", "~> 3.1.1"
gem "pubid", "~> 2.0" # 2.0.3+: edition-2 iso artifact

gem "metanorma-plugin-lutaml", "~> 0.7"

eval_gemfile("Gemfile.devel") rescue nil

gem "metanorma-utils", "~> 2.0.11" # GcBudget (utils#54) + the array-join asciidoctor table cell buffer (utils#55/#56); 2.0.9+ adds the noko_html/AnchorRanges/UUID/encoder perf work

gem "svg_conform", "~> 0.2.6" # 0.2.6 ships the corrected metadata


gem "ogc-gml", "1.2.3" # 1.2.4's nokogiri->moxml swap breaks UnitsML MathML parity (lutaml/ogc-gml#35); unpin at 1.2.5
