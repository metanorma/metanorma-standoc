require_relative "ref_date_id"

module Asciidoctor
  module Standoc
    module Refs
      def iso_publisher(bib, code)
        code.sub(/ .*$/, "").split("/").each do |abbrev|
          bib.contributor do |c|
            c.role **{ type: "publisher" }
            c.organization do |org|
              organization(org, abbrev, true)
            end
          end
        end
      end

      def plaintxt
        { format: "text/plain" }
      end

      def ref_attributes(match)
        { id: match[:anchor], type: "standard" }
      end

      def isorefrender1(bib, match, yr, allp = "")
        bib.title(**plaintxt) { |i| i << ref_normalise(match[:text]) }
        docid(bib, match[:usrlbl]) if match[:usrlbl]
        docid(bib, id_and_year(match[:code], yr) + allp)
        docnumber(bib, match[:code])
      end

      def isorefmatches(xml, match)
        yr = norm_year(match[:year])
        ref = fetch_ref xml, match[:code], yr,
                        title: match[:text], usrlbl: match[:usrlbl],
                        lang: (@lang || :all)
        return use_my_anchor(ref, match[:anchor]) if ref

        xml.bibitem **attr_code(ref_attributes(match)) do |t|
          isorefrender1(t, match, yr)
          yr and t.date **{ type: "published" } do |d|
            set_date_range(d, yr)
          end
          iso_publisher(t, match[:code])
        end
      end

      def isorefmatches2(xml, match)
        ref = fetch_ref xml, match[:code], nil,
                        no_year: true, note: match[:fn],
                        title: match[:text], usrlbl: match[:usrlbl],
                        lang: (@lang || :all)
        return use_my_anchor(ref, match[:anchor]) if ref

        isorefmatches2_1(xml, match)
      end

      def isorefmatches2_1(xml, match)
        xml.bibitem **attr_code(ref_attributes(match)) do |t|
          isorefrender1(t, match, "--")
          t.date **{ type: "published" } do |d|
            d.on "--"
          end
          iso_publisher(t, match[:code])
          unless match[:fn].nil?
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
              p << (match[:fn]).to_s
            end
          end
        end
      end

      def isorefmatches3(xml, match)
        yr = norm_year(match[:year])
        hasyr = !yr.nil? && yr != "--"
        ref = fetch_ref(xml, match[:code], hasyr ? yr : nil,
                        all_parts: true, no_year: yr == "--",
                        text: match[:text], usrlbl: match[:usrlbl],
                        lang: (@lang || :all))
        return use_my_anchor(ref, match[:anchor]) if ref

        isorefmatches3_1(xml, match, yr, hasyr, ref)
      end

      def isorefmatches3_1(xml, match, yr, _hasyr, _ref)
        xml.bibitem(**attr_code(ref_attributes(match))) do |t|
          isorefrender1(t, match, yr, " (all parts)")
          conditional_date(t, match, yr == "--")
          iso_publisher(t, match[:code])
          if match.names.include?("fn") && match[:fn]
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
              p << (match[:fn]).to_s
            end
          end
          t.extent **{ type: "part" } do |e|
            e.referenceFrom "all"
          end
        end
      end

      def refitem_render1(match, code, bib)
        if code[:type] == "path"
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "URI" }
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "citation" }
        end
        docid(bib, match[:usrlbl]) if match[:usrlbl]
        docid(bib, /^\d+$/.match?(code[:id]) ? "[#{code[:id]}]" : code[:id])
        code[:type] == "repo" and
          bib.docidentifier code[:key], **{ type: "repository" }
      end

      def refitem_render(xml, match, code)
        xml.bibitem **attr_code(id: match[:anchor]) do |t|
          t.formattedref **{ format: "application/x-isodoc+xml" } do |i|
            i << ref_normalise_no_format(match[:text])
          end
          refitem_render1(match, code, t)
          docnumber(t, code[:id]) unless /^\d+$|^\(.+\)$/.match?(code[:id])
        end
      end

      MALFORMED_REF = "no anchor on reference, markup may be malformed: see "\
        "https://www.metanorma.com/author/topics/document-format/bibliography/ , "\
        "https://www.metanorma.com/author/iso/topics/markup/#bibliographies".freeze

      def analyse_ref_nofetch(ret)
        return ret unless m = /^nofetch\((?<id>.+)\)$/.match(ret[:id])

        ret.merge(id: m[:id], nofetch: true)
      end

      def analyse_ref_repo_path(ret)
        return ret unless m =
                            /^(?<type>repo|path):\((?<key>[^,]+),?(?<id>.*)\)$/.match(ret[:id])

        id = m[:id].empty? ? m[:key].sub(%r{^[^/]+/}, "") : m[:id]
        ret.merge(id: id, type: m[:type], key: m[:key], nofetch: true)
      end

      def analyse_ref_numeric(ret)
        return ret unless /^\d+$/.match?(ret[:id])

        ret.merge(numeric: true)
      end

      # ref id = (usrlbl)code[:-]year
      # code = nofetch(code) | (repo|path):(key,code) | \[? number \]? | ident
      def analyse_ref_code(code)
        ret = { id: code }
        return ret if code.blank?

        analyse_ref_nofetch(analyse_ref_repo_path(analyse_ref_numeric(ret)))
      end

      # TODO: alternative where only title is available
      def refitem(xml, item, node)
        m = NON_ISO_REF.match(item) and return refitem1(xml, item, m)
        @log.add("AsciiDoc Input", node, "#{MALFORMED_REF}: #{item}")
        nil
      end

      def refitem1(xml, _item, match)
        code = analyse_ref_code(match[:code])
        unless code[:id] && code[:numeric] || code[:nofetch]
          ref = fetch_ref(xml, code[:id],
                          match.names.include?("year") ? match[:year] : nil,
                          title: match[:text],
                          usrlbl: match[:usrlbl], lang: (@lang || :all)) and
            return use_my_anchor(ref, match[:anchor])
        end

        refitem_render(xml, match, code)
      end

      def ref_normalise(ref)
        ref.gsub(/&amp;amp;/, "&amp;").gsub(%r{^<em>(.*)</em>}, "\\1")
      end

      def ref_normalise_no_format(ref)
        ref.gsub(/&amp;amp;/, "&amp;")
      end

      ISO_REF =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+|IEV)
      (:(?<year>[0-9][0-9-]+))?\]</ref>,?\s*(?<text>.*)$}xm.freeze

      ISO_REF_NO_YEAR =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+):
      (--|&\#821[12];)\]</ref>,?\s*
        (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?,?\s?(?<text>.*)$}xm
          .freeze

      ISO_REF_ALL_PARTS =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9]+)
      (:(?<year>--|&\#821[12];|[0-9][0-9-]+))?\s
      \(all\sparts\)\]</ref>,?\s*
        (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>,?\s?)?(?<text>.*)$}xm.freeze

      NON_ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>[^\]]+?)
      ([:-](?<year>(19|20)[0-9][0-9][0-9-]*))?\]</ref>,?\s*(?<text>.*)$}xm
        .freeze

      def reference1_matches(item)
        matched = ISO_REF.match item
        matched2 = ISO_REF_NO_YEAR.match item
        matched3 = ISO_REF_ALL_PARTS.match item
        [matched, matched2, matched3]
      end

      def reference1(node, item, xml)
        matched, matched2, matched3 = reference1_matches(item)
        if matched3.nil? && matched2.nil? && matched.nil?
          refitem(xml, item, node)
        elsif !matched.nil? then isorefmatches(xml, matched)
        elsif !matched2.nil? then isorefmatches2(xml, matched2)
        elsif !matched3.nil? then isorefmatches3(xml, matched3)
        end
      end
    end
  end
end
