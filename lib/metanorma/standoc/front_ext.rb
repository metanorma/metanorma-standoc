module Metanorma
  module Standoc
    module Front
      def metadata_ics(node, xml)
        ics = node.attr("library-ics")
        ics&.split(/,\s*/)&.each do |i|
          xml.ics do |elem|
            add_noko_elem(elem, "code", i)
            icsdata = Isoics.fetch i
            elem.text_ icsdata.description
          end
        end
      end

      def metadata_ext(node, ext)
        metadata_doctype(node, ext)
        metadata_subdoctype(node, ext)
        metadata_flavor(node, ext)
        metadata_ics(node, ext)
        structured_id(node, ext)
        metadata_coverpage_images(node, ext)
      end

      def structured_id(node, xml); end

      def metadata_doctype(node, xml)
        add_noko_elem(xml, "doctype", doctype(node))
      end

      def metadata_subdoctype(node, xml)
        add_noko_elem(xml, "subdoctype", node.attr("docsubtype"))
      end

      def metadata_flavor(_node, ext)
        add_noko_elem(ext, "flavor", processor.new.asciidoctor_backend.to_s)
      end

      def metadata_coverpage_images(node, xml)
        %w(coverpage-image innercoverpage-image tocside-image
           backpage-image).each do |n|
          if a = node.attr(n)
            xml.send n do |c|
              a.split(",").each do |x|
                c.image src: x
              end
            end
          end
        end
      end
    end
  end
end
