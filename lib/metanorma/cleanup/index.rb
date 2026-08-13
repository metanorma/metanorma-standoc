module Metanorma
  module Standoc
    module Index
      # normalize-space(.) rather than normalize-space(text()): index terms
      # wrapped entirely in formatting (<em>a priori</em>, stem) have no
      # direct text nodes but are not empty
      EMPTY_INDEX_XPATH =
        "//index[not(.//primary[normalize-space(.)]) " \
        "or .//secondary[. and not(normalize-space(.))] " \
        "or .//tertiary[. and not(normalize-space(.))]]".freeze

      def index_cleanup(xmldoc)
        para_index_cleanup(xmldoc)
        block_index_cleanup(xmldoc)
        index_empty_check(xmldoc)
      end

      def index_empty_check(xmldoc)
        xmldoc.xpath(EMPTY_INDEX_XPATH).each do |i|
          @log.add("STANDOC_64", i, params: [empty_index_context(i)])
        end
      end

      def empty_index_context(node)
        ctx = node.ancestors.find { |a| a["id"] || a["anchor"] }
        ctx ? (ctx["id"] || ctx["anchor"]) : "(unknown location)"
      end

      def block_index_cleanup(xmldoc)
        xmldoc.xpath("//quote | //td | //th | //formula | //li | //dt | " \
                     "//dd | //example | //note | //figure | //sourcecode | " \
                     "//admonition | //termnote | //termexample | //form  | " \
                     "//requirement | //recommendation | //permission | " \
                     "//imagemap | //svgmap").each do |b|
          b.xpath("./p[indexterm]").each do |p|
            indexterm_para?(p) or next
            p.replace(p.children)
          end
        end
      end

      def indexterm_para?(para)
        p = para.dup
        p.xpath("./index").each(&:remove)
        p.text.strip.empty?
      end

      def include_indexterm?(elem)
        elem.nil? and return false
        !%w(image literal sourcecode).include?(elem.name)
      end

      def para_index_cleanup(xmldoc)
        xmldoc.xpath("//p[index]").select { |p| indexterm_para?(p) }
          .each do |p|
            para_index_cleanup1(p, p.previous_element, p.next_element)
          end
      end

      def para_index_cleanup1(para, prev, foll)
        if include_indexterm?(prev)
          prev << para.remove.children
        elsif include_indexterm?(foll) # && !foll.children.empty?
          foll.add_first_child para.remove.children
        end
      end

      # Inside a term, index elements must live within a designation's name,
      # which admits (PureTextElement | index | index-xref)*; the term model
      # does not admit them as bare children of a designation or the term.
      # term_index_relocate moves any such misplaced index there afterwards.
      # metanorma/metanorma-standoc#1237
      def term_designation_name(elem)
        elem&.at("./expression/name | ./letter-symbol/name")
      end

      DESIGNATIONS = %w(preferred admitted deprecates).freeze

      def designation?(elem)
        DESIGNATIONS.include?(elem&.name)
      end

      # Relocate index / index-xref elements that ended up as bare children of a
      # designation or a term -- positions the term model does not admit -- into
      # a designation's name, which admits index / index-xref. This catches
      # designation-adjacent index paragraphs whose designation was still
      # macro-wrapped (e.g. after alt:[]) when para_index_cleanup ran, so it did
      # not recognise the designation. metanorma/metanorma-standoc#1237
      def term_index_relocate(xmldoc)
        xmldoc.xpath("//#{DESIGNATIONS.join(' | //')}").each do |d|
          name = term_designation_name(d) or next
          d.xpath("./index | ./index-xref").each { |i| name << i.remove }
        end
        xmldoc.xpath("//term").each do |term|
          term.xpath("./index | ./index-xref").each do |i|
            d = preceding_designation(i) ||
              term.at("./#{DESIGNATIONS.join(' | ./')}")
            name = term_designation_name(d) or next
            name << i.remove
          end
        end
      end

      def preceding_designation(node)
        el = node.previous_element
        el = el.previous_element until el.nil? || designation?(el)
        el
      end

      def term_index_cleanup(xmldoc)
        @index_terms or return
        xmldoc.xpath("//preferred").each do |p|
          index_cleanup1(p.at("./expression/name | ./letter-symbol/name"),
                         p.xpath("./field-of-application | ./usage-info")
            &.map(&:text)&.join(", "))
        end
        xmldoc.xpath("//definitions/dl/dt").each do |p|
          index_cleanup1(p, "")
        end
      end

      def index_cleanup1(term, fieldofappl)
        term or return
        # The auto-index primary is the designation text; existing index /
        # index-xref children (e.g. folded in from term-adjacent index
        # paragraphs, metanorma/metanorma-standoc#1237) are themselves index
        # entries and must not be nested inside this new primary.
        idx = term.children
          .reject { |c| %w(index index-xref).include?(c.name) }
          .map(&:to_xml).join
        fieldofappl.empty? or idx += ", &#x3c;#{fieldofappl}&#x3e;"
        term << "<index><primary>#{idx}</primary></index>"
      end
    end
  end
end
