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
          @log.add("Images", i.parent,
                   "Image not found: #{i['src']}", severity: 0)
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
        @log.add("Images", img.parent,
                 "Corrupt PNG image detected: #{e.message}")
      end

      TOO_BIG_IMG_ERR = <<~ERR.freeze
        Image too large for Data URI encoding: disable Data URI encoding (`:data-uri-image: false`), or set `:data-uri-maxsize: 0`
      ERR

      def image_toobig(doc)
        @dataurimaxsize.zero? and return
        doc.xpath("//image").each do |i|
          i["src"].size > @dataurimaxsize and
            @log.add("Images", i.parent, TOO_BIG_IMG_ERR, severity: 0)
        end
      end
    end
  end
end
