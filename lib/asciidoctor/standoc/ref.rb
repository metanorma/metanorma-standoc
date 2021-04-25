require_relative "ref_date_id"

module Asciidoctor
  module Standoc
    module Refs
      def iso_publisher(bib, code)
        code.sub(/ .*$/, "").split(/\//).each do |abbrev|
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

      def ref_attributes(m)
        { id: m[:anchor], type: "standard" }
      end

      def isorefrender1(bib, m, yr, allp = "")
        bib.title(**plaintxt) { |i| i << ref_normalise(m[:text]) }
        docid(bib, m[:usrlbl]) if m[:usrlbl]
        docid(bib, id_and_year(m[:code], yr) + allp)
        docnumber(bib, m[:code])
      end

      def isorefmatches(xml, m)
        yr = norm_year(m[:year])
        ref = fetch_ref xml, m[:code], yr, title: m[:text], usrlbl: m[:usrlbl],
          lang: (@lang || :all)
        return use_my_anchor(ref, m[:anchor]) if ref

        xml.bibitem **attr_code(ref_attributes(m)) do |t|
          isorefrender1(t, m, yr)
          yr and t.date **{ type: "published" } do |d|
            set_date_range(d, yr)
          end
          iso_publisher(t, m[:code])
        end
      end

      def isorefmatches2(xml, m)
        ref = fetch_ref xml, m[:code], nil, no_year: true, note: m[:fn],
          title: m[:text], usrlbl: m[:usrlbl], lang: (@lang || :all)
        return use_my_anchor(ref, m[:anchor]) if ref

        isorefmatches2_1(xml, m)
      end

      def isorefmatches2_1(xml, m)
        xml.bibitem **attr_code(ref_attributes(m)) do |t|
          isorefrender1(t, m, "--")
          t.date **{ type: "published" } do |d|
            d.on "--"
          end
          iso_publisher(t, m[:code])
          unless m[:fn].nil?
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
            p << (m[:fn]).to_s
            end
          end
        end
      end

      def isorefmatches3(xml, m)
        yr = norm_year(m[:year])
        hasyr = !yr.nil? && yr != "--"
        ref = fetch_ref(xml, m[:code], hasyr ? yr : nil,
                        all_parts: true,
                        no_year: yr == "--", text: m[:text], usrlbl: m[:usrlbl],
                        lang: (@lang || :all))
        return use_my_anchor(ref, m[:anchor]) if ref

        isorefmatches3_1(xml, m, yr, hasyr, ref)
      end

      def isorefmatches3_1(xml, m, yr, _hasyr, _ref)
        xml.bibitem(**attr_code(ref_attributes(m))) do |t|
          isorefrender1(t, m, yr, " (all parts)")
          conditional_date(t, m, yr == "--")
          iso_publisher(t, m[:code])
          if m.names.include?("fn") && m[:fn]
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
              p << (m[:fn]).to_s
            end
          end
          t.extent **{ type: "part" } do |e|
            e.referenceFrom "all"
          end
        end
      end

      def refitem_render1(m, code, bib)
        if code[:type] == "path"
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "URI" }
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "citation" }
        end
        docid(bib, m[:usrlbl]) if m[:usrlbl]
        docid(bib, /^\d+$/.match?(code[:id]) ? "[#{code[:id]}]" : code[:id])
        code[:type] == "repo" and
          bib.docidentifier code[:key], **{ type: "repository" }
      end

      def refitem_render(xml, m, code)
        xml.bibitem **attr_code(id: m[:anchor]) do |t|
          t.formattedref **{ format: "application/x-isodoc+xml" } do |i|
            i << ref_normalise_no_format(m[:text])
          end
          refitem_render1(m, code, t)
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

      def refitem1(xml, _item, m)
        code = analyse_ref_code(m[:code])
        unless code[:id] && code[:numeric] || code[:nofetch]
          ref = fetch_ref(xml, code[:id],
                          m.names.include?("year") ? m[:year] : nil,
                          title: m[:text],
                          usrlbl: m[:usrlbl], lang: (@lang || :all))
          return use_my_anchor(ref, m[:anchor]) if ref
        end
        refitem_render(xml, m, code)
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
