require "date"
require "nokogiri"
require "htmlentities"
require "pathname"
require_relative "./front_contributor"
require "isoics"

module Metanorma
  module Standoc
    module Front
      def metadata_id(node, xml)
        id = node.attr("docidentifier") || metadata_id_build(node)
        xml.docidentifier id
      end

      def metadata_id_build(node)
        part, subpart = node&.attr("partnumber")&.split(/-/)
        id = node.attr("docnumber") || ""
        id += "-#{part}" if part
        id += "-#{subpart}" if subpart
        id
      end

      def metadata_other_id(node, xml)
        a = node.attr("isbn") and xml.docidentifier a, type: "ISBN"
        a = node.attr("isbn10") and xml.docidentifier a, type: "ISBN10"
        csv_split(node.attr("additional-docidentifier"), ",")&.each do |n|
          t, v = n.split(":", 2)
          xml.docidentifier v, type: t
        end
        xml.docnumber node.attr("docnumber")
      end

      def metadata_version(node, xml)
        xml.edition node.attr("edition") if node.attr("edition")
        xml.version do |v|
          v.revision_date node.attr("revdate") if node.attr("revdate")
          v.draft node.attr("draft") if node.attr("draft")
        end
      end

      def metadata_status(node, xml)
        xml.status do |s|
          s.stage (node.attr("status") || node.attr("docstage") || "published")
          node.attr("docsubstage") and s.substage node.attr("docsubstage")
          node.attr("iteration") and s.iteration node.attr("iteration")
        end
      end

      def metadata_committee(node, xml)
        node.attr("technical-committee") or return
        xml.editorialgroup do |a|
          committee_component("technical-committee", node, a)
        end
      end

      def metadata_ics(node, xml)
        ics = node.attr("library-ics")
        ics&.split(/,\s*/)&.each do |i|
          xml.ics do |elem|
            elem.code i
            icsdata = Isoics.fetch i
            elem.text_ icsdata.description
          end
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
        date and xml.date type: type do |d|
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
          xml.date type: type do |d|
            d.on date
          end
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
          .sub(/-in$/, "In")
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
          desc.nil? or r.description desc.gsub(/-/, " ")
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

      def metadata_ext(node, ext)
        metadata_doctype(node, ext)
        metadata_subdoctype(node, ext)
        metadata_committee(node, ext)
        metadata_ics(node, ext)
      end

      def metadata_doctype(node, xml)
        xml.doctype doctype(node)
      end

      def metadata_subdoctype(node, xml)
        s = node.attr("docsubtype") and xml.subdoctype s
      end

      def metadata_note(node, xml); end

      def metadata_series(node, xml); end

      def title(node, xml)
        title_english(node, xml)
        title_otherlangs(node, xml)
      end

      def title_english(node, xml)
        ["en"].each do |lang|
          at = { language: lang, format: "text/plain" }
          xml.title **attr_code(at) do |t|
            t << (Metanorma::Utils::asciidoc_sub(node.attr("title") ||
                                                 node.attr("title-en")) ||
            node.title)
          end
        end
      end

      def title_otherlangs(node, xml)
        node.attributes.each do |k, v|
          /^title-(?<titlelang>.+)$/ =~ k or next
          titlelang == "en" and next
          xml.title v, { language: titlelang, format: "text/plain" }
        end
      end
    end
  end
end
