require "pngcheck"

module Metanorma
  module Standoc
    module Validate
      def image_validate(doc)
        image_exists(doc)
        image_toobig(doc)
        png_validate(doc)
      end

      def image_exists(doc)
        doc.xpath("//image").each do |i|
          Vectory::Utils::url?(i["src"]) and next
          Vectory::Utils::datauri?(i["src"]) and next
          expand_path(i["src"]) and next
          @log.add("STANDOC_44", i.parent, params: [i["src"]])
        end
      end

      def expand_path(loc)
        relative_path = File.join(@localdir, loc)
        [loc, relative_path].detect do |p|
          File.exist?(p) ? p : nil
        end
      end

      def png_validate(doc)
        doc.xpath("//image[@mimetype = 'image/png']").each do |i|
          Vectory::Utils::url?(i["src"]) and next
          decoded = if Vectory::Utils::datauri?(i["src"])
                      Vectory::Utils::decode_datauri(i["src"])[:data]
                    else
                      path = expand_path(i["src"]) or next
                      File.binread(path)
                    end
          png_validate1(i, decoded)
        end
      end

      def png_validate1(img, buffer)
        PngCheck.check_buffer(buffer)
      rescue PngCheck::CorruptPngError => e
        @log.add("STANDOC_45", img.parent, params: [e.message])
      end

      def image_toobig(doc)
        @dataurimaxsize.zero? and return
        doc.xpath("//image").each do |i|
          i["src"].size > @dataurimaxsize and
            @log.add("STANDOC_46", i.parent)
        end
      end
    end
  end
end
