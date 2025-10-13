require "date"
require "pathname"
require_relative "./front_contributor"
require_relative "./front_ext"
require "isoics"

module Metanorma
  module Standoc
    module Front
      def metadata_id(node, xml)
        id = node.attr("docidentifier") || metadata_id_build(node)
        xml.docidentifier id, primary: "true"
      end

      def metadata_id_build(node)
        part, subpart = node&.attr("partnumber")&.split("-")
        id = node.attr("docnumber") || ""
        id += "-#{part}" if part
        id += "-#{subpart}" if subpart
        id
      end

      def metadata_other_id(node, xml)
        a = node.attr("isbn") and xml.docidentifier a, type: "ISBN"
        a = node.attr("isbn10") and xml.docidentifier a, type: "ISBN10"
        csv_split(node.attr("docidentifier-additional"), ",")&.each do |n|
          t, v = n.split(":", 2)
          xml.docidentifier v, type: t
        end
        xml.docnumber node.attr("docnumber")
      end

      def metadata_version(node, xml)
        draft = metadata_version_value(node)
        xml.edition node.attr("edition") if node.attr("edition")
        xml.version do |v|
          v.revision_date node.attr("revdate") if node.attr("revdate")
          v.draft draft if draft
        end
      end

      def metadata_version_value(node)
        draft = node.attr("version") and return draft
        draft = node.attr("draft") or return nil
        draft.empty? and return nil
        draft
      end

      def metadata_status(node, xml)
        xml.status do |s|
          s.stage (node.attr("status") || node.attr("docstage") || "published")
          node.attr("docsubstage") and s.substage node.attr("docsubstage")
          node.attr("iteration") and s.iteration node.attr("iteration")
        end
      end

      def metadata_source(node, xml)
        node.attr("uri") && xml.uri(node.attr("uri"))
        %w(xml html pdf doc relaton).each do |t|
          node.attr("#{t}-uri") && xml.uri(node.attr("#{t}-uri"), type: t)
        end
      end

      def metadata_date1(node, xml, type)
        date = node.attr("#{type}-date")
        date and xml.date(type:) do |d|
          d.on date
        end
      end

      def datetypes
        %w{ published accessed created implemented obsoleted
            confirmed updated corrected issued circulated unchanged received
            vote-started vote-ended announced }
      end

      def metadata_date(node, xml)
        datetypes.each { |t| metadata_date1(node, xml, t) }
        node.attributes.each_key do |a|
          a == "date" || /^date_\d+$/.match(a) or next
          type, date = node.attr(a).split(/ /, 2)
          type or next
          xml.date(type:) { |d| d.on date }
        end
      end

      def metadata_language(node, xml)
        xml.language (node.attr("language") || "en")
        l = node.attr("locale") and xml.locale l
      end

      def metadata_script(node, xml)
        xml.script (node.attr("script") ||
                    Metanorma::Utils.default_script(node.attr("language")))
      end

      def relaton_relations
        %w(part-of translated-from)
      end

      def relaton_relation_descriptions
        {}
      end

      def metadata_relations(node, xml)
        relaton_relations.each do |t|
          metadata_getrelation(node, xml, t)
        end
        relaton_relation_descriptions.each do |k, v|
          metadata_getrelation(node, xml, v, k)
        end
      end

      def relation_normalise(type)
        type.sub(/-by$/, "By").sub(/-of$/, "Of").sub(/-from$/, "From")
          .sub(/-in$/, "In").sub(/^has-([a-z])/) { "has#{$1.upcase}" }
      end

      def metadata_getrelation(node, xml, type, desc = nil)
        docs = node.attr(desc || type) or return
        @c.decode(docs).split(/;\s*/).each do |d|
          metadata_getrelation1(d, xml, type, desc)
        end
      end

      def metadata_getrelation1(doc, xml, type, desc)
        id = doc.split(/,\s*/)
        xml.relation type: relation_normalise(type) do |r|
          desc.nil? or r.description desc.tr("-", " ")
          fetch_ref(r, doc, nil, **{}) or r.bibitem do |b|
            b.title id[1] || "--"
            b.docidentifier id[0]
          end
        end
      end

      def metadata_keywords(node, xml)
        node.attr("keywords") or return
        node.attr("keywords").split(/,\s*/).each do |kw|
          xml.keyword kw
        end
      end

      def metadata_classifications(node, xml)
        csv_split(node.attr("classification"), ",")&.each do |c|
          vals = c.split(/:/, 2)
          vals.size == 1 and vals = ["default", vals[0]]
          xml.classification vals[1], type: vals[0]
        end
      end

      def metadata(node, xml)
        title node, xml
        metadata_source(node, xml)
        metadata_id(node, xml)
        metadata_other_id(node, xml)
        metadata_date(node, xml)
        metadata_author(node, xml)
        metadata_publisher(node, xml)
        metadata_sponsor(node, xml)
        metadata_version(node, xml)
        metadata_note(node, xml)
        metadata_language(node, xml)
        metadata_script(node, xml)
        metadata_status(node, xml)
        metadata_copyright(node, xml)
        metadata_relations(node, xml)
        metadata_series(node, xml)
        metadata_classifications(node, xml)
        metadata_keywords(node, xml)
        xml.ext do
          metadata_ext(node, xml)
        end
      end

      def metadata_note(node, xml); end

      def metadata_series(node, xml); end

      def title(node, xml)
        title_main(node, xml)
        title_other(node, xml)
        title_fallback(node, xml)
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
        xml.title **attr_code(language: language, type: type) do |t|
          t << Metanorma::Utils::asciidoc_sub(content)
        end
      end

      def title_fallback(node, xml)
        xml.parent.at("./title[not(normalize-space(.)='')]") and return
        add_title_xml(xml, node.attr("doctitle"), @lang, "main")
      end
    end
  end
end
