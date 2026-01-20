module Metanorma
  module Standoc
    module Cleanup
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
        idx = term.children.dup
        fieldofappl.empty? or idx << ", &#x3c;#{fieldofappl}&#x3e;"
        term << "<index><primary>#{idx.to_xml}</primary></index>"
      end
    end
  end
end
