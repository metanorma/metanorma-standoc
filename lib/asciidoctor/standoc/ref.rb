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
        return id unless year
        "#{id}:#{year}"
      end

      def docid(t, code)
        type, code1 = /^\[\d+\]$|^\([^)]+\).*$/.match(code) ?
          ["metanorma", Utils::mn_code(code)] :
          @bibdb&.docid_type(code) || [nil, code]
        code1.sub!(/^nofetch\((.+)\)$/, "\\1")
        t.docidentifier code1, **attr_code(type: type)
      end

      def norm_year(yr)
        return "--" if /^\&\#821[12];$/.match yr
        yr
      end

      def isorefmatches(xml, m)
        yr = norm_year(m[:year])
        ref = fetch_ref xml, m[:code], yr, title: m[:text], usrlbl: m[:usrlbl]
        return use_my_anchor(ref, m[:anchor]) if ref
        xml.bibitem **attr_code(ref_attributes(m)) do |t|
          t.title(**plaintxt) { |i| i << ref_normalise(m[:text]) }
          docid(t, m[:usrlbl]) if m[:usrlbl]
          docid(t, id_and_year(m[:code], yr))
          yr and t.date **{ type: "published" } do |d|
            set_date_range(d, yr)
          end
          iso_publisher(t, m[:code])
        end
      end

      def isorefmatches2(xml, m)
        ref = fetch_ref xml, m[:code], nil, no_year: true, note: m[:fn],
          title: m[:text], usrlbl: m[:usrlbl]
        return use_my_anchor(ref, m[:anchor]) if ref

        xml.bibitem **attr_code(ref_attributes(m)) do |t|
          t.title(**plaintxt) { |i| i << ref_normalise(m[:text]) }
          docid(t, m[:usrlbl]) if m[:usrlbl]
          docid(t, id_and_year(m[:code], "--"))
          t.date **{ type: "published" } do |d|
            d.on "--"
          end
          iso_publisher(t, m[:code])
          m[:fn].nil? or t.note(**plaintxt) { |p| p << "ISO DATE: #{m[:fn]}" }
        end
      end

      def conditional_date(t, m, noyr)
        m.names.include?("year") and !m[:year].nil? and
          t.date(**{ type: "published" }) do |d|
          if noyr then d.on "--"
          else
            set_date_range(d, norm_year(m[:year]))
          end
        end
      end

      def isorefmatches3(xml, m)
        yr = norm_year(m[:year])
        hasyr =  m.names.include?("year") && yr != "--"
        noyr =  m.names.include?("year") && yr == "--"
        ref = fetch_ref xml, m[:code], hasyr ? yr : nil,
          all_parts: true, no_year: noyr, text: m[:text], usrlbl: m[:usrlbl]
        return use_my_anchor(ref, m[:anchor]) if ref

        xml.bibitem(**attr_code(ref_attributes(m))) do |t|
          t.title(**plaintxt) { |i| i << ref_normalise(m[:text]) }
          docid(t, m[:usrlbl]) if m[:usrlbl]
          docid(t, id_and_year(m[:code], yr) + " (all parts)")
          conditional_date(t, m, noyr)
          iso_publisher(t, m[:code])
          m.names.include?("fn") && m[:fn] and
            t.note(**plaintxt) { |p| p << "ISO DATE: #{m[:fn]}" }
          t.extent **{ type: 'part' } do |e|
            e.referenceFrom "all"
          end
        end
      end

      def fetch_ref(xml, code, year, **opts)
        return nil if opts[:no_year]
        code = code.sub(/^\([^)]+\)/, "")
        hit = @bibdb&.fetch(code, year, opts)
        return nil if hit.nil?
        xml.parent.add_child(Utils::smart_render_xml(hit, code, opts[:title], opts[:usrlbl]))
        xml
      rescue RelatonBib::RequestError
        #warn "Could not retrieve #{code}: no access to online site"
        @log.add("Bibliography", nil, "Could not retrieve #{code}: no access to online site")
        nil
      end

      def refitem_render(xml, m)
        xml.bibitem **attr_code(id: m[:anchor]) do |t|
          t.formattedref **{ format: "application/x-isodoc+xml" } do |i|
            i << ref_normalise_no_format(m[:text])
          end
          docid(t, m[:usrlbl]) if m[:usrlbl]
          docid(t, /^\d+$/.match(m[:code]) ? "[#{m[:code]}]" : m[:code])
        end
      end

      MALFORMED_REF = 
        "no anchor on reference, markup may be malformed: "\
        "see https://www.metanorma.com/author/topics/document-format/bibliography/ , "\
        "https://www.metanorma.com/author/iso/topics/markup/#bibliographies".freeze

      # TODO: alternative where only title is available
      def refitem(xml, item, node)
        unless m = NON_ISO_REF.match(item)
          #Utils::warning(node, MALFORMED_REF, item)
          @log.add("Asciidoctor Input", node, "#{MALFORMED_REF}: #{item}")
          return
        end
        unless m[:code] && /^\d+$/.match(m[:code])
          ref = fetch_ref xml, m[:code],
            m.names.include?("year") ? m[:year] : nil, title: m[:text], usrlbl: m[:usrlbl]
          return use_my_anchor(ref, m[:anchor]) if ref
        end
        refitem_render(xml, m)
      end

      def ref_normalise(ref)
        ref.
          gsub(/&amp;amp;/, "&amp;").
          gsub(%r{^<em>(.*)</em>}, "\\1")
      end

      def ref_normalise_no_format(ref)
        ref.
          gsub(/&amp;amp;/, "&amp;")
      end

      ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+|IEV)
      (:(?<year>[0-9][0-9-]+))?\]</ref>,?\s*
        (?<text>.*)$}xm

        ISO_REF_NO_YEAR = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9-]+):(--|\&\#821[12]\;)\]</ref>,?\s*
        (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?,?\s?(?<text>.*)$}xm

        ISO_REF_ALL_PARTS = %r{^<ref\sid="(?<anchor>[^"]+)">
        \[(?<usrlbl>\([^)]+\))?(?<code>(ISO|IEC)[^0-9]*\s[0-9]+)(:(?<year>--|\&\#821[12]\;|[0-9][0-9-]+))?\s
        \(all\sparts\)\]</ref>,?\s*
          (<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>,?\s?)?(?<text>.*)$}xm

          NON_ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
        \[(?<usrlbl>\([^)]+\))?(?<code>[^\]]+?)([:-](?<year>(19|20)[0-9][0-9]))?\]</ref>,?\s*
          (?<text>.*)$}xm

          # @param item [String]
          # @return [Array<MatchData>]
          def reference1_matches(item)
            matched = ISO_REF.match item
            matched2 = ISO_REF_NO_YEAR.match item
            matched3 = ISO_REF_ALL_PARTS.match item
            [matched, matched2, matched3]
        end

        # @param node [Asciidoctor::List]
        # @param item [String]
        # @param xml [Nokogiri::XML::Builder]
        def reference1(node, item, xml)
          matched, matched2, matched3 = reference1_matches(item)
          if matched3.nil? && matched2.nil? && matched.nil?
            refitem(xml, item, node)
          elsif !matched.nil? then isorefmatches(xml, matched)
          elsif !matched2.nil? then isorefmatches2(xml, matched2)
          elsif !matched3.nil? then isorefmatches3(xml, matched3)
          end
        end

        def reference(node)
          noko do |xml|
            node.items.each do |item|
              reference1(node, item.text, xml)
            end
          end.join
        end

        def global_ievcache_name
          "#{Dir.home}/.iev/cache"
        end

        def local_ievcache_name(cachename)
          return nil if cachename.nil?
          cachename += "_iev" unless cachename.empty?
          cachename = "iev" if cachename.empty?
          "#{cachename}/cache"
        end
    end
  end
end
