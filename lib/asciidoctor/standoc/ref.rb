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

      def isorefmatchescode(match)
        yr = norm_year(match[:year])
        { code: match[:code],
          year: yr, match: match,
          title: match[:text], usrlbl: match[:usrlbl],
          lang: (@lang || :all) }
      end

      def use_retrieved_relaton(item, xml)
        xml.parent.add_child(smart_render_xml(item[:doc], item[:ref][:code],
                                              item[:ref]))
        use_my_anchor(xml, item[:ref][:match][:anchor])
      end

      def isorefmatchesout(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else
          xml.bibitem **attr_code(ref_attributes(item[:ref][:match])) do |t|
            isorefrender1(t, item[:ref][:match], item[:ref][:year])
            item[:ref][:year] and t.date **{ type: "published" } do |d|
              set_date_range(d, item[:ref][:year])
            end
            iso_publisher(t, item[:ref][:match][:code])
          end
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

      def isorefmatches2code(match)
        { code: match[:code], no_year: true,
          note: match[:fn],
          year: nil, match: match,
          title: match[:text], usrlbl: match[:usrlbl],
          lang: (@lang || :all) }
      end

      def isorefmatches2out(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else
          isorefmatches2_1(xml, item[:ref][:match])
        end
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

      def isorefmatches3code(match)
        yr = norm_year(match[:year])
        hasyr = !yr.nil? && yr != "--"
        { code: match[:code],
          year: hasyr ? yr : nil,
          all_parts: true, no_year: yr == "--",
          match: match, yr: yr, hasyr: hasyr,
          text: match[:text], usrlbl: match[:usrlbl],
          lang: (@lang || :all) }
      end

      def isorefmatches3out(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else
          isorefmatches3_1(xml, item[:ref][:match], item[:ref][:yr],
                           item[:ref][:hasyr], item[:doc])
        end
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

      def refitemcode(item, node)
        m = NON_ISO_REF.match(item) and return refitem1code(item, m)
        @log.add("AsciiDoc Input", node, "#{MALFORMED_REF}: #{item}")
        {}
      end

      def refitem1(xml, _item, match)
        code = analyse_ref_code(match[:code])
        unless (code[:id] && code[:numeric]) || code[:nofetch]
          ref = fetch_ref(xml, code[:id],
                          match.names.include?("year") ? match[:year] : nil,
                          title: match[:text],
                          usrlbl: match[:usrlbl], lang: (@lang || :all)) and
            return use_my_anchor(ref, match[:anchor])
        end

        refitem_render(xml, match, code)
      end

      def refitem1code(_item, match)
        code = analyse_ref_code(match[:code])
        if (code[:id] && code[:numeric]) || code[:nofetch]
          { code: nil, match: match, analyse_code: code }
        else
          { code: code[:id], analyse_code: code,
            year: match.names.include?("year") ? match[:year] : nil,
            title: match[:text], match: match,
            usrlbl: match[:usrlbl], lang: (@lang || :all) }
        end
      end

      def refitemout(item, xml)
        return nil if item[:ref][:match].nil?

        item[:doc] or
          return refitem_render(xml, item[:ref][:match],
                                item[:ref][:analyse_code])

        use_retrieved_relaton(item, xml)
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

      # elim
      def reference1(node, item, xml)
        matched, matched2, matched3 = reference1_matches(item)
        if matched3.nil? && matched2.nil? && matched.nil?
          refitem(xml, item, node)
        elsif !matched.nil? then isorefmatches(xml, matched)
        elsif !matched2.nil? then isorefmatches2(xml, matched2)
        elsif !matched3.nil? then isorefmatches3(xml, matched3)
        end
      end

      def reference1code(item, node)
        matched, matched2, matched3 = reference1_matches(item)
        if matched3.nil? && matched2.nil? && matched.nil?
          refitemcode(item, node).merge(process: 0)
        elsif !matched.nil? then isorefmatchescode(matched).merge(process: 1)
        elsif !matched2.nil? then isorefmatches2code(matched2).merge(process: 2)
        elsif !matched3.nil? then isorefmatches3code(matched3).merge(process: 3)
        end
      end

      def reference1out(item, xml)
        case item[:ref][:process]
        when 0 then refitemout(item, xml)
        when 1 then isorefmatchesout(item, xml)
        when 2 then isorefmatches2out(item, xml)
        when 3 then isorefmatches3out(item, xml)
        end
      end

      def reference(node)
        refs = node.items.each_with_object([]) do |b, m|
          m << reference1code(b.text, node)
        end
        # results = refs.each_with_index.with_object(Queue.new) do |(ref, i), res|
        # fetch_ref_async(ref) { |doc| res << [ref, i, doc] }
        results = refs.each_with_index.with_object(Queue.new) do |(ref, i), res|
          fetch_ref_async(ref.merge(ord: i), i, res)
        end
        while results.size < refs.size
          sleep 1
        end
        noko do |xml|
          ret = refs.each.with_object([]) do |_, m|
            # begin
            # require "byebug"; byebug
            ref, i, doc = results.pop
            if doc.is_a?(RelatonBib::RequestError)
              # do what needs to propagate error
              @log.add("Bibliography", nil, "Could not retrieve #{ref[:code]}: "\
                                            "no access to online site")
              m[i.to_i] = { ref: ref }
              # res << [ref, idx, nil]
            else
              m[i.to_i] = { doc: doc, ref: ref }
            end
          end
          ret.each { |b| reference1out(b, xml) }
        end.join
      end
    end
  end
end
