require "date"
require "pathname"
require_relative "./front_contributor"
require_relative "./front_ext"
require_relative "./front_title"
require "isoics"
require "isodoc"

module Metanorma
  module Standoc
    module Front
      # specifically the primary identifier
      def metadata_id(node, xml)
        if id = node.attr("docidentifier")
          add_noko_elem(xml, "docidentifier",
                        id, primary: "true", boilerplate: true,
                            type: metadata_id_primary_type)
        else
          metadata_id_dynamic(node, xml)
        end
      end

      def metadata_id_primary_type; end

      def metadata_id_primary(node, xml)
        id = metadata_id_build(node)
        add_noko_elem(xml, "docidentifier", id, primary: "true",
                                                type: metadata_id_primary_type)
      end

      def metadata_id_build(node)
        part, subpart = node&.attr("partnumber")&.split("-")
        id = node.attr("docnumber") || ""
        id += "-#{part}" if part
        id += "-#{subpart}" if subpart
        id
      end

      def metadata_id_nonprimary(node, xml); end

      def metadata_other_id(node, xml)
        metadata_id_nonprimary(node, xml)
        a = node.attr("isbn") and
          add_noko_elem(xml, "docidentifier", a, type: "ISBN")
        a = node.attr("isbn10") and
          add_noko_elem(xml, "docidentifier", a, type: "ISBN10")
        csv_split(node.attr("docidentifier-additional"), ",")&.each do |n|
          t, v = n.split(":", 2)
          add_noko_elem(xml, "docidentifier", v, type: t)
        end
        add_noko_elem(xml, "docnumber", node.attr("docnumber"))
      end

      def metadata_version(node, xml)
        draft = metadata_version_value(node)
        add_noko_elem(xml, "edition", node.attr("edition"))
        xml.version do |v|
          add_noko_elem(v, "revision_date", node.attr("revdate"))
          add_noko_elem(v, "draft", draft)
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
          add_noko_elem(s, "stage",
                        node.attr("status") || node.attr("docstage") || "published")
          add_noko_elem(s, "substage", node.attr("docsubstage"))
          add_noko_elem(s, "iteration", node.attr("iteration"))
        end
      end

      def metadata_source(node, xml)
        add_noko_elem(xml, "uri", node.attr("uri"))
        %w(xml html pdf doc relaton).each do |t|
          add_noko_elem(xml, "uri", node.attr("#{t}-uri"), type: t)
        end
      end

      def metadata_date1(node, xml, type)
        date = node.attr("#{type}-date")
        date and xml.date(type:) do |d|
          add_noko_elem(d, "on", date)
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
          xml.date(type:) { |d| add_noko_elem(d, "on", date) }
        end
      end

      def metadata_language(node, xml)
        add_noko_elem(xml, "language", node.attr("language") || "en")
        add_noko_elem(xml, "locale", node.attr("locale"))
      end

      def metadata_script(node, xml)
        add_noko_elem(xml, "script", node.attr("script") ||
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
            add_noko_elem(b, "title", id[1] || "--")
            add_noko_elem(b, "docidentifier", id[0])
          end
        end
      end

      def metadata_keywords(node, xml)
        node.attr("keywords") or return
        node.attr("keywords").split(/,\s*/).each do |kw|
          add_noko_elem(xml, "keyword", kw)
        end
      end

      def metadata_classifications(node, xml)
        csv_split(node.attr("classification"), ",")&.each do |c|
          vals = c.split(/:/, 2)
          vals.size == 1 and vals = ["default", vals[0]]
          add_noko_elem(xml, "classification", vals[1], type: vals[0])
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
    end
  end
end
