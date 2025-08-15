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
        ret = reference_queue(*references_fetch(refs))
        joint_prep = joint_entries_prep(ret)
        out = references2xml(ret)
        joint_entries(out, joint_prep).compact.map { |x| to_xml(x) }.join
      end

      def references2xml(ret)
        out = ret.map do |b|
          b.nil? ? nil : noko { |xml| reference1out(b, xml) }
        end
        out.map { |x| x.nil? ? nil : Nokogiri::XML(x).root }
      end

      def references_fetch(refs)
        i = 0
        ret = refs.each_with_object(Queue.new) do |ref, res|
          i = fetch_ref_async(ref.merge(ord: i), i, res)
        end
        [ret, i]
      end

      def reference_queue(results, size)
        (1..size).each.with_object([]) do |_, m|
          ref, i, doc = results.pop
          m[i.to_i] = { ref: }
          if doc.is_a?(RelatonBib::RequestError)
            @log.add("Bibliography", nil,
                     "Could not retrieve #{ref[:code]}: " \
                     "no access to online site", severity: 1)
          else m[i.to_i][:doc] = doc end
        end
      end

      def joint_entries(out, joint_prep)
        joint_prep.each do |k, v|
          v[:merge]&.each do |i|
            merge_entries(out[k], out[i]) and out[i] = nil
          end
          v[:dual]&.each do |i|
            dual_entries(out[k], out[i]) and out[i] = nil
          end
        end
        out
      end

      # append publishers docids of add to base
      def merge_entries(base, add)
        merge_publishers(base, add)
        merge_docids(base, add)
        merge_urls(base, add)
      end

      def merge_publishers(base, add)
        ins = base.at("//contributor[last()]") || base.children[-1]
        add.xpath("//contributor[role/@type = 'publisher']").reverse_each do |p|
          ins.next = p
        end
      end

      def merge_docids(base, add)
        ins = base.at("//docidentifier[last()]")
        [ins, add].each do |v|
          v.at("//docidentifier[@primary = 'true']") or
            v.at("//docidentifier")["primary"] = true
        end
        add.xpath("//docidentifier").reverse_each do |p|
          ins.next = p
        end
      end

      def merge_urls(base, add)
        ins = base.at("./uri[last()]") || base.at("./title[last()]")
        add.xpath("./uri").reverse_each do |p|
          ins.next = p
        end
      end

      def dual_entries(base, add)
        ins = docrelation_insert(base)
        ins.next = "<relation type='hasReproduction'>#{to_xml(add)}</relation>"
      end

      def docrelation_insert(base)
        %w(relation copyright status abstract locale language note version
           edition contributor date docnumber docidentifier).each do |v|
          r = base.at("//#{v}[last()]") and return r
        end
      end

      JOINT_REFS = %i(merge dual).freeze

      def joint_entries_prep(out)
        out.each_with_object({}) do |r, m|
          JOINT_REFS.each do |v|
            if i = r&.dig(:ref, "#{v}_into".to_sym)
              m[i] ||= { "#{v}": [] }
              m[i][v][r[:ref][:merge_order]] = r[:ref][:ord]
            end
          end
        end
      end

      def global_ievcache_name
        "#{Dir.home}/.iev/cache"
      end

      def local_ievcache_name(cachename)
        cachename.nil? and return nil
        cachename += "_iev" unless cachename.empty?
        cachename = "iev" if cachename.empty?
        "#{cachename}/cache"
      end

      def fetch_ref(xml, code, year, **opts)
        opts[:no_year] and return nil
        require 'debug'; binding.b
        _, code = extract_balanced_parentheses(code)
        hit = fetch_ref1(code, year, opts) or return nil
        xml.parent.add_child(smart_render_xml(hit, code, opts))
        xml
      rescue RelatonBib::RequestError
        @log.add("Bibliography", nil, "Could not retrieve #{code}: " \
                                      "no access to online site", severity: 1)
        nil
      end

      def supply_ref_prefix(ret)
        ret
      end

      def fetch_ref1(code, year, opts)
        code = supply_ref_prefix(code)
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
        ref[:code] &&= supply_ref_prefix(ref[:code])
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
        fetch_ref_async_dual(ref, idx, idx + 1, res)
      end

      def fetch_ref_async_dual(ref, orig, idx, res)
        JOINT_REFS.each do |m|
          ref.dig(:analyse_code, m)&.each_with_index do |code, i|
            @bibdb.fetch_async(code, nil, ref.merge(ord: idx)) do |doc|
              res << [ref.merge("#{m}_into": orig, merge_order: i, ord: idx),
                      idx, doc]
            end
            idx += 1
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
                      amend: item.dig(:ref, :analyse_code, :amend),
                      hidden: item.dig(:ref, :analyse_code, :hidden),
                      dropid: item.dig(:ref, :analyse_code, :dropid))
      end

      def init_bib_caches(node)
        @no_isobib and return
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
          if @flush_caches
            FileUtils.rm_f @iev_globalname unless @iev_globalname.nil?
            FileUtils.rm_f @iev_localname unless @iev_localname.nil?
          end
        end
        # @iev = Iev::Db.new(globalname, localname) unless @no_isobib
      end
    end
  end
end
