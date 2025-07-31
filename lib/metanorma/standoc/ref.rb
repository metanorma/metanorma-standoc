require_relative "ref_utility"
require_relative "ref_queue"

module Metanorma
  module Standoc
    module Refs
      def iso_publisher(bib, code)
        code.sub(/(?<! ) .*$/, "").split("/").each do |abbrev|
          bib.contributor do |c|
            c.role type: "publisher"
            c.organization do |org|
              organization(org, abbrev, nil, true)
            end
          end
        end
      end

      def isorefrender1(bib, match, code, year, allp = "")
        bib.title(**plaintxt) { |i| i << ref_normalise(match[:text]) }
        # refitem_render_formattedref(bib, match[:text])
        docid(bib, match[:usrlbl]) if match[:usrlbl]
        docid(bib, code[:usrlabel]) if code && code[:usrlabel]
        docid(bib, id_and_year(match[:code], year) + allp)
        docnumber(bib, match[:code])
      end

      def isorefmatchescode(match, _item)
        code = analyse_ref_code(match[:code])
        yr = norm_year(match[:year])
        { code: match[:code], year: yr, match:,
          title: match[:text], usrlbl: match[:usrlbl] || code[:usrlabel],
          analyse_code: code, lang: @lang || :all }
      end

      def isorefmatchesout(item, xml)
        item[:doc] and return use_retrieved_relaton(item, xml)
        r = item[:ref]
        xml.bibitem **attr_code(ref_attributes(r[:match])) do |t|
          isorefrender1(t, r[:match], r[:analyse_code], r[:year])
          y = r[:year] and t.date type: "published" do |d|
            set_date_range(d, y)
          end
          iso_publisher(t, r[:match][:code])
        end
      end

      def isorefmatches2code(match, _item)
        code = analyse_ref_code(match[:code])
        { code: match[:code], no_year: true, lang: @lang || :all,
          note: match[:fn], year: nil, match:, analyse_code: code,
          title: match[:text], usrlbl: match[:usrlbl] || code[:usrlabel] }
      end

      def isorefmatches2out(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else isorefmatches2_1(xml, item[:ref][:match],
                              item[:ref][:analyse_code])
        end
      end

      def isorefmatches2_1(xml, match, code)
        xml.bibitem **attr_code(ref_attributes(match)) do |t|
          isorefrender1(t, match, code, "--")
          t.date type: "published" do |d|
            d.on "--"
          end
          iso_publisher(t, match[:code])
          unless match[:fn].nil?
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
              p << match[:fn].to_s
            end
          end
        end
      end

      def isorefmatches3code(match, _item)
        code = analyse_ref_code(match[:code])
        yr = norm_year(match[:year])
        hasyr = !yr.nil? && yr != "--"
        { code: match[:code], match:, yr:, hasyr:,
          year: hasyr ? yr : nil, lang: @lang || :all,
          all_parts: true, no_year: yr == "--",
          title: match[:text], usrlbl: match[:usrlbl] || code[:usrlabel] }
      end

      def isorefmatches3out(item, xml)
        if item[:doc] then use_retrieved_relaton(item, xml)
        else isorefmatches3_1(
          xml, item[:ref][:match], item[:ref][:analyse_code],
          item[:ref][:yr], item[:ref][:hasyr], item[:doc]
        )
        end
      end

      def isorefmatches3_1(xml, match, code, year, _hasyr, _ref)
        xml.bibitem(**attr_code(ref_attributes(match))) do |t|
          isorefrender1(t, match, code, year, " (all parts)")
          conditional_date(t, match, year == "--")
          iso_publisher(t, match[:code])
          if match.names.include?("fn") && match[:fn]
            t.note(**plaintxt.merge(type: "Unpublished-Status")) do |p|
              p << match[:fn].to_s
            end
          end
          t.extent type: "part" do |e|
            e.referenceFrom "all"
          end
        end
      end

      def refitem_render1(match, code, bib)
        refitem_uri(code, bib)
        match[:usrlbl] and docid(bib, match[:usrlbl])
        code[:usrlabel] and docid(bib, code[:usrlabel])
        i = code[:id] and
          docid(bib, /^\d+$/.match?(i) ? "[#{i}]" : i, code[:type])
        code[:type] == "repo" and
          bib.docidentifier code[:key], type: "repository"
      end

      def refitem_uri(code, bib)
        if code[:type] == "path"
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), type: "URI"
          bib.uri code[:key].sub(/\.[a-zA-Z0-9]+$/, ""), type: "citation"
        end
        if code[:type] == "attachment"
          bib.uri code[:key], type: "attachment"
          bib.uri code[:key], type: "citation"
        end
      end

      def refitem_render(xml, match, code)
        xml.bibitem **refitem_render_attrs(match, code) do |t|
          refitem_render_formattedref(t, match[:text])
          yr_match = refitem1yr(code[:id])
          refitem_render1(match, code, t)
          /^\d+$|^\(.+\)$/.match?(code[:id]) or
            docnumber(t, code[:id]&.sub(/[:-](19|20)[0-9][0-9]$/, ""))
          conditional_date(t, yr_match || match, false)
        end
      end

      def refitem_render_attrs(match, code)
        attr_code(anchor: match[:anchor], suppress_identifier: code[:dropid],
                  amend: code[:amend], hidden: code[:hidden],
                  id: "_#{UUIDTools::UUID.random_create}")
      end

      def refitem_render_formattedref(bibitem, title)
        (title.nil? || title.empty?) and title = @i18n.no_information_available
        bibitem.formattedref format: "application/x-isodoc+xml" do |i|
          i << ref_normalise_no_format(title)
        end
      end

      # TODO: alternative where only title is available
      def refitemcode(item, node)
        m = NON_ISO_REF.match(item) and return refitem1code(item, m).compact
        m = NON_ISO_REF1.match(item) and return refitem1code(item, m).compact
        @log.add("AsciiDoc Input", node, "#{MALFORMED_REF}: #{item}",
                 severity: 1)
        {}
      end

      def refitem1code(_item, match)
        code = analyse_ref_code(match[:code])
        ((code[:id] && code[:numeric]) || code[:nofetch]) and
          return { code: nil, match:, analyse_code: code,
                   hidden: code[:hidden] }
        { code: code[:id], analyse_code: code, localfile: code[:localfile],
          year: (m = refitem1yr(code[:id])) ? m[:year] : nil,
          title: match[:text], match:, hidden: code[:hidden],
          usrlbl: match[:usrlbl] || code[:usrlabel], lang: @lang || :all }
      end

      def refitem1yr(code)
        yr_match = /[:-](?<year>(?:19|20)[0-9][0-9])$/.match(code)
        /[:-](?:19|20)[0-9][0-9].*?[:-](?:19|20)[0-9][0-9]$/.match(code) and
          yr_match = nil
        yr_match
      end

      def refitemout(item, xml)
        item[:ref][:match].nil? and return nil
        item[:doc] or return refitem_render(xml, item[:ref][:match],
                                            item[:ref][:analyse_code])
        use_retrieved_relaton(item, xml)
      end

      def reference1_matches(item)
        matched = ISO_REF.match item
        matched2 = ISO_REF_NO_YEAR.match item
        matched3 = ISO_REF_ALL_PARTS.match item
        [matched, matched2, matched3]
      end

      def reference1code(item, node)
        m, m2, m3 = reference1_matches(item)
        m3.nil? && m2.nil? && m.nil? and
          return refitemcode(item, node).merge(process: 0)
        !m.nil? and return isorefmatchescode(m, item).merge(process: 1)
        !m2.nil? and return isorefmatches2code(m2, item).merge(process: 2)
        !m3.nil? and return isorefmatches3code(m3, item).merge(process: 3)
      end

      def reference1out(item, xml)
        item[:ref][:analyse_code] ||= analyse_ref_code(item[:ref][:code])
        case item[:ref][:process]
        when 0 then refitemout(item, xml)
        when 1 then isorefmatchesout(item, xml)
        when 2 then isorefmatches2out(item, xml)
        when 3 then isorefmatches3out(item, xml)
        end
      end

      include ::Metanorma::Standoc::Regex
    end
  end
end
