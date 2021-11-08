module Asciidoctor
  module Standoc
    module Section
      def in_biblio?
        @biblio
      end

      def in_norm_ref?
        @norm_ref
      end

      #       def reference(node)
      #         noko do |xml|
      #           node.items.each { |item| reference1(node, item.text, xml) }
      #         end.join
      #       end

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
        hit = @bibdb&.fetch(code, year, opts)
        return nil if hit.nil?

        xml.parent.add_child(smart_render_xml(hit, code, opts))
        xml
      rescue RelatonBib::RequestError
        @log.add("Bibliography", nil, "Could not retrieve #{code}: "\
                                      "no access to online site")
        #require "byebug"; byebug
        nil
      end

      #       def fetch_ref_async(ref, &block)
      #         if ref[:code].nil? then yield nil
      #         else
      #           begin
      #             @bibdb&.fetch_async(ref[:code], ref[:year], ref, block)
      #           rescue RelatonBib::RequestError
      #             @log.add("Bibliography", nil, "Could not retrieve #{ref[:code]}: "\
      #                                           "no access to online site")
      #             yield nil
      #           end
      #         end
      #       end

      def fetch_ref_async(ref, idx, res)
        if ref[:code].nil? || ref[:no_year] || @bibdb.nil?
          res << [ref, idx, nil]
        else
          warn "3## #{idx}: #{ref}"
          @bibdb.fetch_async(ref[:code], ref[:year], ref) do |doc|
            res << [ref, idx, doc]
            warn "FETCHED: #{res.size}"
          end
        end
      end

      def emend_biblio(xml, code, title, usrlbl)
        unless xml.at("/bibitem/docidentifier[not(@type = 'DOI')][text()]")
          @log.add("Bibliography", nil,
                   "ERROR: No document identifier retrieved for #{code}")
          xml.root << "<docidentifier>#{code}</docidentifier>"
        end
        unless xml.at("/bibitem/title[text()]")
          @log.add("Bibliography", nil,
                   "ERROR: No title retrieved for #{code}")
          xml.root << "<title>#{title || '(MISSING TITLE)'}</title>"
        end
        usrlbl and xml.at("/bibitem/docidentifier").next =
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

      def init_bib_caches(node)
        return if @no_isobib

        global = !@no_isobib_cache && !node.attr("local-cache-only")
        local = node.attr("local-cache") || node.attr("local-cache-only")
        local = nil if @no_isobib_cache
        @bibdb = Relaton::DbCache.init_bib_caches(
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
