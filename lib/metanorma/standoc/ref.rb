require_relative "ref_utility"

module Metanorma
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

      def isorefrender1(bib, match, year, allp = "")
        bib.title(**plaintxt) { |i| i << ref_normalise(match[:text]) }
        docid(bib, match[:usrlbl]) if match[:usrlbl]
        docid(bib, id_and_year(match[:code], year) + allp)
        docnumber(bib, match[:code])
      end

      def isorefmatchescode(match)
        yr = norm_year(match[:year])
        { code: match[:code], year: yr, match: match,
          title: match[:text], usrlbl: match[:usrlbl],
          lang: (@lang || :all) }
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

      def isorefmatches2code(match)
        { code: match[:code], no_year: true,
          note: match[:fn], year: nil, match: match,
          title: match[:text], usrlbl: match[:usrlbl],
          lang: (@lang || :all) }
      end

      def isorefmatches2out(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else isorefmatches2_1(xml, item[:ref][:match])
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

      def isorefmatches3code(match)
        yr = norm_year(match[:year])
        hasyr = !yr.nil? && yr != "--"
        { code: match[:code], match: match, yr: yr, hasyr: hasyr,
          year: hasyr ? yr : nil,
          all_parts: true, no_year: yr == "--",
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
        # code[:id].sub!(/[:-](19|20)[0-9][0-9]$/, "")
        docid(bib, match[:usrlbl]) if match[:usrlbl]
        docid(bib, /^\d+$/.match?(code[:id]) ? "[#{code[:id]}]" : code[:id])
        code[:type] == "repo" and
          bib.docidentifier code[:key], **{ type: "repository" }
      end

      def refitem_render(xml, match, code)
        xml.bibitem **attr_code(id: match[:anchor],
                                hidden: code[:hidden]) do |t|
          t.formattedref **{ format: "application/x-isodoc+xml" } do |i|
            i << ref_normalise_no_format(match[:text])
          end
          yr_match = /[:-](?<year>(?:19|20)[0-9][0-9])\b/.match(code[:id])
          refitem_render1(match, code, t)
          /^\d+$|^\(.+\)$/.match?(code[:id]) or
            docnumber(t, code[:id].sub(/[:-](19|20)[0-9][0-9]$/, ""))
          conditional_date(t, yr_match || match, false)
        end
      end

      # TODO: alternative where only title is available
      def refitemcode(item, node)
        m = NON_ISO_REF.match(item) and return refitem1code(item, m).compact
        m = NON_ISO_REF1.match(item) and return refitem1code(item, m).compact
        @log.add("AsciiDoc Input", node, "#{MALFORMED_REF}: #{item}")
        {}
      end

      def refitem1code(_item, match)
        code = analyse_ref_code(match[:code])
        ((code[:id] && code[:numeric]) || code[:nofetch]) and
          return { code: nil, match: match, analyse_code: code,
                   hidden: code[:hidden] }
        year = refitem1yr(code[:id])
        { code: code[:id], analyse_code: code,
          year: year,
          title: match[:text], match: match, hidden: code[:hidden],
          usrlbl: match[:usrlbl], lang: (@lang || :all) }
      end

      def refitem1yr(code)
        yr_match = /[:-](?<year>(?:19|20)[0-9][0-9])\b/.match(code)
        yr_match ? yr_match[:year] : nil
      end

      def refitemout(item, xml)
        return nil if item[:ref][:match].nil?

        item[:doc] or return refitem_render(xml, item[:ref][:match],
                                            item[:ref][:analyse_code])
        use_retrieved_relaton(item, xml)
      end

      ISO_REF =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9-]+|IEV)
      (?::(?<year>[0-9][0-9-]+))?\]</ref>,?\s*(?<text>.*)$}xm.freeze

      ISO_REF_NO_YEAR =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9-]+):
      (?:--|&\#821[12];)\]</ref>,?\s*
        (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?,?\s?(?<text>.*)$}xm
          .freeze

      ISO_REF_ALL_PARTS =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9]+)
      (?::(?<year>--|&\#821[12];|[0-9][0-9-]+))?\s
      \(all\sparts\)\]</ref>,?\s*
        (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>,?\s?)?(?<text>.*)$}xm.freeze

      NON_ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>.+?)\]</ref>,?\s*(?<text>.*)$}xm
        .freeze

      NON_ISO_REF1 = %r{^<ref\sid="(?<anchor>[^"]+)">
      (?<usrlbl>\([^)]+\))?(?<code>.+?)</ref>,?\s*(?<text>.*)$}xm
        .freeze

      def reference1_matches(item)
        matched = ISO_REF.match item
        matched2 = ISO_REF_NO_YEAR.match item
        matched3 = ISO_REF_ALL_PARTS.match item
        [matched, matched2, matched3]
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
        reference_populate(refs)
      end

      def reference_populate(refs)
        results = refs.each_with_index.with_object(Queue.new) do |(ref, i), res|
          fetch_ref_async(ref.merge(ord: i), i, res)
        end
        ret = reference_queue(refs, results)
        noko do |xml|
          ret.each { |b| reference1out(b, xml) }
        end.join
      end

      def reference_queue(refs, results)
        refs.each.with_object([]) do |_, m|
          ref, i, doc = results.pop
          m[i.to_i] = { ref: ref }
          if doc.is_a?(RelatonBib::RequestError)
            @log.add("Bibliography", nil, "Could not retrieve #{ref[:code]}: "\
                                          "no access to online site")
          else m[i.to_i][:doc] = doc
          end
        end
      end
    end
  end
end
