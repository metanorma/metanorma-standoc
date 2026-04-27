module Metanorma
  module Standoc
    module Front
      def title(node, xml)
        title_main(node, xml)
        title_other(node, xml)
        title_fallback(node, xml)
        title_nums(node, xml, @lang)
      end

      # English plain title: :title: or implicit, typed as main
      def title_main(node, xml)
        title = node.attr("title")
        title.nil? || title.empty? and return
        node.attr("title-en") and return
        add_title_xml(xml, title, "en", "main")
      end

      def title_other(node, xml)
        node.attributes.each do |k, v|
          /^title-(?<remainder>.+)$/ =~ k or next
          type, language = remainder.split("-", 2)
          if language.nil?
            language = type
            type = "main"
          end
          add_title_xml(xml, v, language, type)
        end
      end

      def add_title_xml(xml, content, language, type)
        add_noko_elem(xml, "title", Metanorma::Utils::asciidoc_sub(content),
                      language: language, type: type)
      end

      def title_fallback(node, xml)
        xml.parent.at("./title[not(normalize-space(.)='')]") and return
        add_title_xml(xml, node.attr("doctitle"), @lang, "main")
      end

      def title_nums(node, xml, lang)
        @i18n_cache ||= {}
        @i18n_cache[lang] ||= isodoc(lang, ::Metanorma::Utils::default_script(lang),
                                     nil, i18nyaml_path(node)).i18n
        ret = title_nums_prep(node)
        ret[:part] && ret[:subpart] and ret[:part] += "&#x2013;#{ret[:subpart]}"
        ret.delete(:subpart)
        ret.each do |k, v|
          title_num_prefix(k, v, xml, lang)
        end
      end

      def title_nums_prep(node)
        part, subpart = node.attr("partnumber")&.split("-")
        { part:, subpart:, amendment: node.attr("amendment-number"),
          corrigendum: node.attr("corrigendum-number"),
          addendum: node.attr("addendum-number") }
      end

      def title_num_prefix(key, value, xml, lang)
        prefix = @i18n_cache[lang].get.dig("title_prefixes", key.to_s) or return
        value && !value.empty? or return
        title = "#{prefix}&#xa0;#{value}"
        add_title_xml(xml, title, lang, "title-#{key}-prefix")
      end
    end
  end
end
