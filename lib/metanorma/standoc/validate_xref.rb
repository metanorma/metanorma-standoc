module Metanorma
  module Standoc
    module Validate
      def repeat_id_validate1(elem)
        if @doc_ids[elem["id"]]
          @log.add("Anchors", elem, "Anchor #{elem['id']} has already been " \
                                    "used at line #{@doc_ids[elem['id']]}")
          @fatalerror << "Multiple instances of same ID: #{elem['id']}"
        end
        @doc_ids[elem["id"]] = elem.line
      end

      def repeat_id_validate(doc)
        @doc_ids = {}
        doc.xpath("//*[@id]").each do |x|
          repeat_id_validate1(x)
        end
      end

      # manually check for xref/@target, xref/@to integrity
      def xref_validate(doc)
        @doc_xrefs = doc.xpath("//xref/@target | //xref/@to")
          .each_with_object({}) do |x, m|
          m[x.text] = x
          @doc_ids[x.text] and next
          @log.add("Anchors", x.parent,
                   "Crossreference target #{x} is undefined")
        end
      end
    end
  end
end
