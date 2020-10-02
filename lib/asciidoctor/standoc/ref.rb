module Asciidoctor
  module Standoc
    module Lists
      def iso_publisher(t, code)
        code.sub(/ .*$/, "").split(/\//).each do |abbrev|
          t.contributor do |c|
            c.role **{ type: "publisher" }
            c.organization do |org|
              organization(org, abbrev)
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

      def set_date_range(date, text)
        matched = /^(?<from>[0-9]+)(-+(?<to>[0-9]+))?$/.match text
        return unless matched[:from]
        if matched[:to]
          date.from matched[:from]
          date.to matched[:to]
        else
          date.on matched[:from]
        end
      end

      def use_my_anchor(ref, id)
        ref.parent.elements.last["id"] = id
        ref
      end

      def id_and_year(id, year)
        year ? "#{id}:#{year}" : id
      end

      def docid(t, code)
        type, code1 = /^\[\d+\]$|^\([^)]+\).*$/.match(code) ?
          ["metanorma", mn_code(code)] : @bibdb&.docid_type(code) || [nil, code]
        code1.sub!(/^nofetch\((.+)\)$/, "\\1")
        t.docidentifier **attr_code(type: type) do |d|
          d << code1
        end
      end

      def docnumber(t, code)
        t.docnumber do |d|
          d << HTMLEntities.new.decode(code).sub(/^[^\d]*/, "")
        end
      end

      def norm_year(yr)
        /^\&\#821[12];$/.match(yr) ? "--" : yr
      end

      def isorefrender1(t, m, yr, allp = "")
        t.title(**plaintxt) { |i| i << ref_normalise(m[:text]) }
        docid(t, m[:usrlbl]) if m[:usrlbl]
        docid(t, id_and_year(m[:code], yr) + allp)
        docnumber(t, m[:code])
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
          m[:fn].nil? or t.note(**plaintxt.merge(type: "ISO DATE")) do |p|
            p << "#{m[:fn]}"
          end
        end
      end

      def conditional_date(t, m, noyr)
        m.names.include?("year") and !m[:year].nil? and
          t.date(**{ type: "published" }) do |d|
          noyr and d.on "--" or
            set_date_range(d, norm_year(m[:year]))
        end
      end

      def isorefmatches3(xml, m)
        yr = norm_year(m[:year])
        hasyr = !yr.nil? && yr != "--"
        ref = fetch_ref xml, m[:code], hasyr ? yr : nil, all_parts: true, 
          no_year: yr == "--", text: m[:text], usrlbl: m[:usrlbl],
          lang: (@lang || :all)
        return use_my_anchor(ref, m[:anchor]) if ref
        isorefmatches3_1(xml, m, yr, hasyr, ref)
      end

      def isorefmatches3_1(xml, m, yr, hasyr, ref)
        xml.bibitem(**attr_code(ref_attributes(m))) do |t|
          isorefrender1(t, m, yr, " (all parts)")
          conditional_date(t, m, yr == "--")
          iso_publisher(t, m[:code])
          m.names.include?("fn") && m[:fn] and
            t.note(**plaintxt.merge(type: "ISO DATE")) { |p| p << "#{m[:fn]}" }
          t.extent **{ type: 'part' } do |e|
            e.referenceFrom "all"
          end
        end
      end

      def refitem_render1(m, code, t)
        if code[:type] == "path"
          t.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "URI" }
          t.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), **{ type: "citation" }
        end
        docid(t, m[:usrlbl]) if m[:usrlbl]
        docid(t, /^\d+$/.match(code[:id]) ? "[#{code[:id]}]" : code[:id])
        code[:type] == "repo" and
          t.docidentifier code[:key], **{ type: "repository" }
      end

      def refitem_render(xml, m, code)
        xml.bibitem **attr_code(id: m[:anchor]) do |t|
          t.formattedref **{ format: "application/x-isodoc+xml" } do |i|
            i << ref_normalise_no_format(m[:text])
          end
          refitem_render1(m, code, t)
          docnumber(t, code[:id]) unless /^\d+$|^\(.+\)$/.match(code[:id])
        end
      end

      MALFORMED_REF = "no anchor on reference, markup may be malformed: see "\
        "https://www.metanorma.com/author/topics/document-format/"\
        "bibliography/ , https://www.metanorma.com/author/iso/topics/markup/"\
        "#bibliographies".freeze

      def analyse_ref_nofetch(ret)
        return ret unless m = /^nofetch\((?<id>.+)\)$/.match(ret[:id])
        ret.merge(id: m[:id], nofetch: true)
      end

      def analyse_ref_repo_path(ret)
        return ret unless m =
          /^(?<type>repo|path):\((?<key>[^,]+),(?<id>.+)\)$/.match(ret[:id])
        ret.merge(id: m[:id], type: m[:type], key: m[:key], nofetch: true)
      end

      def analyse_ref_numeric(ret)
        return ret unless /^\d+$/.match(ret[:id])
        ret.merge(numeric: true)
      end

      # ref id = (usrlbl)code[:-]year
      # code = nofetch(code) | (repo|path):(key,code) | \[? number \]? | ident
      def analyse_ref_code(code)
        ret = {id: code}
        return ret if code.nil? || code.empty?
        analyse_ref_nofetch(analyse_ref_repo_path(analyse_ref_numeric(ret)))
      end

      # TODO: alternative where only title is available
      def refitem(xml, item, node)
        m = NON_ISO_REF.match(item) and return refitem1(xml, item, m)
        @log.add("AsciiDoc Input", node, "#{MALFORMED_REF}: #{item}")
        nil
      end

      def refitem1(xml, item, m)
        code = analyse_ref_code(m[:code])
        unless code[:id] && code[:numeric] || code[:nofetch]
          ref = fetch_ref xml, code[:id],
            m.names.include?("year") ? m[:year] : nil, title: m[:text],
            usrlbl: m[:usrlbl], lang: (@lang || :all)
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

      ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+|IEV)
      (:(?<year>[0-9][0-9-]+))?\]</ref>,?\s*
        (?<text>.*)$}xm

        ISO_REF_NO_YEAR = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+):
      (--|\&\#821[12]\;)\]</ref>,?\s*
        (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?,?\s?(?<text>.*)$}xm

        ISO_REF_ALL_PARTS = %r{^<ref\sid="(?<anchor>[^"]+)">
        \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9]+)
        (:(?<year>--|\&\#821[12]\;|[0-9][0-9-]+))?\s
        \(all\sparts\)\]</ref>,?\s*
          (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>,?\s?)?(?<text>.*)$}xm

          NON_ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
        \[(?<usrlbl>\([^)]+\))?(?<code>[^\]]+?)
        ([:-](?<year>(19|20)[0-9][0-9]))?\]</ref>,?\s*(?<text>.*)$}xm

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

        def mn_code(code)
          code.sub(/^\(/, "[").sub(/\).*$/, "]").sub(/^nofetch\((.+)\)$/, "\\1")
        end
    end
  end
end
