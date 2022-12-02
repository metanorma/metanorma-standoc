module Metanorma
  module Standoc
    module Section
      def in_biblio?
        @biblio
      end

      def in_norm_ref?
        @norm_ref
      end

      def bibliography_parse(attrs, xml, node)
        x = biblio_prep(attrs, xml, node) and return x
        @biblio = true
        attrs = attrs.merge(normative: node.attr("normative") || false)
        xml.references **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          xml_section << node.content
        end
        @biblio = false
      end

      def bibitem_parse(attrs, xml, node)
        norm_ref = @norm_ref
        biblio = @biblio
        @biblio = false
        @norm_ref = false
        ret = clause_parse(attrs, xml, node)
        @biblio = biblio
        @norm_ref = norm_ref
        ret
      end

      def norm_ref_parse(attrs, xml, node)
        x = biblio_prep(attrs, xml, node) and return x
        @norm_ref = true
        attrs = attrs.merge(normative: node.attr("normative") || true)
        xml.references **attr_code(attrs) do |xml_section|
          xml_section.title { |t| t << node.title }
          xml_section << node.content
        end
        @norm_ref = false
      end

      def biblio_prep(attrs, xml, node)
        if node.option? "bibitem"
          bibitem_parse(attrs, xml, node)
        else
          node.attr("style") == "bibliography" or
            @log.add("AsciiDoc Input", node,
                     "Section not marked up as [bibliography]!")
          nil
        end
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

      def fetch_ref(xml, code, year, **opts)
        return nil if opts[:no_year]

        code = code.sub(/^\([^)]+\)/, "")
        hit = fetch_ref1(code, year, opts) or return nil
        xml.parent.add_child(smart_render_xml(hit, code, opts))
        xml
      rescue RelatonBib::RequestError
        @log.add("Bibliography", nil, "Could not retrieve #{code}: " \
                                      "no access to online site")
        nil
      end

      def fetch_ref1(code, year, opts)
        if opts[:localfile]
          @local_bibdb.get(code, opts[:localfile])
        else @bibdb&.fetch(code, year, opts)
        end
      end

      def fetch_ref_async(ref, idx, res)
        if ref[:code].nil? || ref[:no_year] || (@bibdb.nil? && !ref[:localfile])
          res << [ref, idx, nil]
        elsif ref[:localfile]
          res << [ref, idx, @local_bibdb.get(ref[:code], ref[:localfile])]
        else fetch_ref_async1(ref, idx, res)
        end
      end

      def fetch_ref_async1(ref, idx, res)
        @bibdb.fetch_async(ref[:code], ref[:year], ref) do |doc|
          res << [ref, idx, doc]
        end
      end

      def emend_biblio(xml, code, title, usrlbl)
        emend_biblio_id(xml, code)
        emend_biblio_title(xml, code, title)
        emend_biblio_usrlbl(xml, usrlbl)
      end

      def emend_biblio_id(xml, code)
        unless xml.at("/bibitem/docidentifier[not(@type = 'DOI')][text()]")
          @log.add("Bibliography", nil,
                   "ERROR: No document identifier retrieved for #{code}")
          xml.root << "<docidentifier>#{code}</docidentifier>"
        end
      end

      def emend_biblio_title(xml, code, title)
        unless xml.at("/bibitem/title[text()]")
          @log.add("Bibliography", nil,
                   "ERROR: No title retrieved for #{code}")
          xml.root << "<title>#{title || '(MISSING TITLE)'}</title>"
        end
      end

      def emend_biblio_usrlbl(xml, usrlbl)
        usrlbl or return
        xml.at("/bibitem/docidentifier").next =
          "<docidentifier type='metanorma'>#{mn_code(usrlbl)}</docidentifier>"
      end

      def smart_render_xml(xml, code, opts)
        xml.respond_to? :to_xml or return nil
        xml = Nokogiri::XML(xml.to_xml(lang: opts[:lang]))
        emend_biblio(xml, code, opts[:title], opts[:usrlbl])
        xml.xpath("//date").each { |d| Metanorma::Utils::endash_date(d) }
        xml.traverse do |n|
          n.text? and n.replace(Metanorma::Utils::smartformat(n.text))
        end
        xml.to_xml.sub(/<\?[^>]+>/, "")
      end

      def use_retrieved_relaton(item, xml)
        xml.parent.add_child(smart_render_xml(item[:doc], item[:ref][:code],
                                              item[:ref]))
        use_my_anchor(xml, item[:ref][:match][:anchor],
                      hidden: item.dig(:ref, :analyse_code, :hidden),
                      dropid: item.dig(:ref, :analyse_code, :dropid))
      end

      def init_bib_caches(node)
        return if @no_isobib

        global = !@no_isobib_cache && !node.attr("local-cache-only")
        local = node.attr("local-cache") || node.attr("local-cache-only")
        local = nil if @no_isobib_cache
        @bibdb = Relaton::Db.init_bib_caches(
          local_cache: local,
          flush_caches: node.attr("flush-caches"),
          global_cache: global,
        )
      end

      def init_iev_caches(node)
        unless @no_isobib_cache || @no_isobib
          node.attr("local-cache-only") or
            @iev_globalname = global_ievcache_name
          @iev_localname = local_ievcache_name(node.attr("local-cache") ||
                                               node.attr("local-cache-only"))
          if node.attr("flush-caches")
            FileUtils.rm_f @iev_globalname unless @iev_globalname.nil?
            FileUtils.rm_f @iev_localname unless @iev_localname.nil?
          end
        end
        # @iev = Iev::Db.new(globalname, localname) unless @no_isobib
      end
    end
  end
end
