module Metanorma
  module Standoc
    module Refs
      def reference(node)
        refs = node.items.each_with_object([]) do |b, m|
          m << reference1code(b.text, node)
        end
        reference_populate(reference_normalise(refs))
      end

      def reference_normalise(refs)
        refs.each do |r|
          r[:code] = @c.decode(r[:code])
            .gsub("\u2009\u2014\u2009", " -- ").strip
        end
      end

      def reference_populate(refs)
        i = 0
        results = refs.each_with_object(Queue.new) do |ref, res|
          i = fetch_ref_async(ref.merge(ord: i), i, res)
        end
        ret = reference_queue(refs, results)
        noko do |xml|
          ret.each { |b| reference1out(b, xml) }
        end.join
      end

      def reference_queue(refs, results)
        out = refs.each.with_object([]) do |_, m|
          ref, i, doc = results.pop
          m[i.to_i] = { ref: ref }
          if doc.is_a?(RelatonBib::RequestError)
            @log.add("Bibliography", nil, "Could not retrieve #{ref[:code]}: " \
                                          "no access to online site")
          else m[i.to_i][:doc] = doc
          end
        end
        merge_entries(out)
      end

      def merge_entries(out)
        out
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

      def unfetchable_ref_code?(ref)
        ref[:code].nil? || ref[:code].empty? || ref[:no_year] ||
          /^\(.+\)$/.match?(ref[:code]) ||
          (@bibdb.nil? && !ref[:localfile])
      end

      def fetch_ref_async(ref, idx, res)
        if unfetchable_ref_code?(ref)
          res << [ref, idx, nil]
          idx += 1
        elsif ref[:localfile]
          res << [ref, idx, @local_bibdb.get(ref[:code], ref[:localfile])]
          idx += 1
        else idx = fetch_ref_async1(ref, idx, res)
        end
        idx
      end

      def fetch_ref_async1(ref, idx, res)
        @bibdb.fetch_async(ref[:code], ref[:year], ref) do |doc|
          res << [ref, idx, doc]
        end
        fetch_ref_async_dual(ref, idx, res)
      end

      def fetch_ref_async_dual(ref, idx, res)
        orig = idx
        %i(merge dual).each do |m|
          ref[:analyze_code][m]&.each_with_index do |doc, i|
            idx += 1
            res << [ref.merge("#{m}_into": orig, merge_order: i, ord: idx), idx,
                    doc]
          end
        end
        idx
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
