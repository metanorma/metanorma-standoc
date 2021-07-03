require_relative "term_lookup_cleanup"

module Asciidoctor
  module Standoc
    module Cleanup
      def termdef_stem_cleanup(xmldoc)
        xmldoc.xpath("//term/p/stem").each do |a|
          if a.parent.elements.size == 1 # para contains just a stem expression
            t = Nokogiri::XML::Element.new("admitted", xmldoc)
            parent = a.parent
            t.children = a.remove
            parent.replace(t)
          end
        end
      end

      def termdomain_cleanup(xmldoc)
        xmldoc.xpath("//p/domain").each do |a|
          prev = a.parent.previous
          prev.next = a.remove
        end
      end

      def termdomain1_cleanup(xmldoc)
        xmldoc.xpath("//domain").each do |d|
          defn = d.at("../definition") and
            defn.previous = d.remove
        end
      end

      def termdefinition_cleanup(xmldoc)
        xmldoc.xpath("//term").each do |d|
          first_child = d.at("./p | ./figure | ./formula") || next
          t = Nokogiri::XML::Element.new("definition", xmldoc)
          first_child.replace(t)
          t << first_child.remove
          d.xpath("./p | ./figure | ./formula").each { |n| t << n.remove }
        end
      end

      def termdef_unnest_cleanup(xmldoc)
        # release termdef tags from surrounding paras
        nodes = xmldoc.xpath("//p/admitted | //p/deprecates")
        while !nodes.empty?
          nodes[0].parent.replace(nodes[0].parent.children)
          nodes = xmldoc.xpath("//p/admitted | //p/deprecates")
        end
      end

      def termdef_subclause_cleanup(xmldoc)
        xmldoc.xpath("//terms[terms]").each { |t| t.name = "clause" }
      end

      def termdocsource_cleanup(xmldoc)
        f = xmldoc.at("//preface | //sections")
        xmldoc.xpath("//termdocsource").each do |s|
          f.previous = s.remove
        end
      end

      def term_children_cleanup(xmldoc)
        xmldoc.xpath("//term").each do |t|
          %w(termnote termexample termsource).each do |w|
            t.xpath("./#{w}").each { |n| t << n.remove }
          end
        end
      end

      def termdef_from_termbase(xmldoc)
        xmldoc.xpath("//term").each do |x|
          if (c = x.at("./origin/termref")) && !x.at("./definition")
            x.at("./origin").previous = fetch_termbase(c["base"], c.text)
          end
        end
      end

      def termnote_example_cleanup(xmldoc)
        xmldoc.xpath("//termnote[not(ancestor::term)]").each do |x|
          x.name = "note"
        end
        xmldoc.xpath("//termexample[not(ancestor::term)]").each do |x|
          x.name = "example"
        end
      end

      def termdef_cleanup(xmldoc)
        Asciidoctor::Standoc::TermLookupCleanup.new(xmldoc, @log).call
        termdef_from_termbase(xmldoc)
        termdef_unnest_cleanup(xmldoc)
        termdef_stem_cleanup(xmldoc)
        termdomain_cleanup(xmldoc)
        termdefinition_cleanup(xmldoc)
        termdomain1_cleanup(xmldoc)
        termnote_example_cleanup(xmldoc)
        termdef_subclause_cleanup(xmldoc)
        term_children_cleanup(xmldoc)
        termdocsource_cleanup(xmldoc)
      end

      # Indices sort after letter but before any following
      # letter (x, x_m, x_1, xa); we use colon to force that sort order.
      # Numbers sort *after* letters; we use thorn to force that sort order.
      def symbol_key(sym)
        key = sym.dup
        key.traverse do |n|
          next unless n.name == "math"

          n.replace(grkletters(MathML2AsciiMath.m2a(n.to_xml)))
        end
        ret = Nokogiri::XML(key.to_xml)
        HTMLEntities.new.decode(ret.text.downcase)
          .gsub(/[\[\]{}<>()]/, "").gsub(/\s/m, "")
          .gsub(/[[:punct:]]|[_^]/, ":\\0").gsub(/`/, "")
          .gsub(/[0-9]+/, "þ\\0")
      end

      def grkletters(x)
        x.gsub(/\b(alpha|beta|gamma|delta|epsilon|zeta|eta|theta|iota|kappa|lambda|mu|nu|xi|omicron|pi|rho|sigma|tau|upsilon|phi|chi|psi|omega)\b/i, "&\\1;")
      end

      def extract_symbols_list(dlist)
        dl_out = []
        dlist.xpath("./dt | ./dd").each do |dtd|
          if dtd.name == "dt"
            dl_out << { dt: dtd.remove, key: symbol_key(dtd) }
          else
            dl_out.last[:dd] = dtd.remove
          end
        end
        dl_out
      end

      def symbols_cleanup(docxml)
        docxml.xpath("//definitions/dl").each do |dl|
          dl_out = extract_symbols_list(dl)
          dl_out.sort! { |a, b| a[:key] <=> b[:key] || a[:dt] <=> b[:dt] }
          dl.children = dl_out.map { |d| d[:dt].to_s + d[:dd].to_s }.join("\n")
        end
        docxml
      end
    end
  end
end
