require "yaml"

module Asciidoctor
  module Standoc
    module I18n
        def load_yaml(lang, script)
          if @i18nyaml then YAML.load_file(@i18nyaml)
          elsif lang == "en"
            YAML.load_file(File.join(File.dirname(__FILE__),
                                     "../../asciidoctor-yaml/i18n-en.yaml"))
          elsif lang == "fr"
            YAML.load_file(File.join(File.dirname(__FILE__),
                                     "../../asciidoctor-yaml/i18n-fr.yaml"))
          elsif lang == "zh" && script == "Hans"
            YAML.load_file(File.join(File.dirname(__FILE__),
                                     "../../asciidoctor-yaml/i18n-zh-Hans.yaml"))
          else
            YAML.load_file(File.join(File.dirname(__FILE__),
                                     "../../asciidoctor-yaml/i18n-en.yaml"))
          end
        end

        def i18n_init(lang, script)
          @lang = lang
          @script = script
          y = load_yaml(lang, script)
          @term_def_boilerplate = y["term_def_boilerplate"] || ""
          @no_terms_boilerplate = y["no_terms_boilerplate"] || ""
          @internal_terms_boilerplate = y["internal_terms_boilerplate"] || ""
          @norm_with_refs_pref = y["norm_with_refs_pref"] || ""
          @norm_empty_pref = y["norm_empty_pref"] || ""
          @external_terms_boilerplate = y["external_terms_boilerplate"] || ""
          @internal_external_terms_boilerplate =
            y["internal_external_terms_boilerplate"] || ""
          @labels = y
        end
      end
    end
  end
