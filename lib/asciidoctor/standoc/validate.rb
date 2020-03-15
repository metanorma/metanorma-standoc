require "asciidoctor/standoc/utils"
require_relative "./validate_section.rb"
require "nokogiri"
require "jing"
require "iev"

module Asciidoctor
  module Standoc
    module Validate

      SOURCELOCALITY = "./termsource/origin/locality[@type = 'clause']/referenceFrom".freeze

      def init_iev
        return nil if @no_isobib
        return @iev if @iev
        @iev = Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        xmldoc.xpath("//term").each do |t|
          /^IEC 60050-/.match(t&.at("./termsource/origin/@citeas")&.text) or next
          pref = t.xpath("./preferred").inject([]) { |m, x| m << x&.text&.downcase }
          locality = t.xpath(SOURCELOCALITY)&.text or next
          @iev = init_iev or return
          iev = @iev.fetch(locality, xmldoc&.at("//language")&.text || "en") or next
          pref.include?(iev.downcase) or
            #warn %(Term "#{pref[0]}" does not match IEV #{locality} "#{iev}")
          @log.add("Bibliography", t, %(Term "#{pref[0]}" does not match IEV #{locality} "#{iev}"))
        end
      end

      def content_validate(doc)
        section_validate(doc)
        repeat_id_validate(doc.root)
        iev_validate(doc.root)
      end

      def repeat_id_validate(doc)
        ids = {}
        doc.xpath("//*[@id]").each do |x|
          if ids[x["id"]]
          @log.add("Anchors", x, "Anchor #{x['id']} has already been used at line #{ids[x['id']]}")
          else
            ids[x["id"]] = x.line
          end
        end
        end

      def schema_validate(doc, schema)
        Tempfile.open(["tmp", ".xml"], :encoding => 'UTF-8') do |f|
          begin
            f.write(doc.to_xml) 
            f.close
            errors = Jing.new(schema).validate(f.path)
            warn "Syntax Valid!" if errors.none?
            errors.each do |error|
              @log.add("Syntax", "XML Line #{"%06d" % error[:line]}:#{error[:column]}", error[:message])
            end
          rescue Jing::Error => e
            abort "Jing failed with error: #{e}"
          ensure
            f.close!
          end
        end
      end

      # RelaxNG cannot cope well with wildcard attributes. So we strip
      # any attributes from FormattedString instances (which can contain
      # xs:any markup, and are signalled with @format) before validation.
      def formattedstr_strip(doc)
        doc.xpath("//*[@format] | //stem | //bibdata//description | "\
                  "//formattedref | //bibdata//note | //bibdata/abstract | "\
                  "//bibitem/abstract | //bibitem/note").each do |n|
          n.elements.each do |e|
            e.traverse do |e1|
              e1.element? and e1.each { |k, _v| e1.delete(k) }
            end
          end
        end
        doc
      end

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "isodoc.rng"))
      end
    end
  end
end
