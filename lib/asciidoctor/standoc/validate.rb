require "asciidoctor/standoc/utils"
require_relative "./validate_section.rb"
require "nokogiri"
require "jing"
require "iev"

module Asciidoctor
  module Standoc
    module Validate

      SOURCELOCALITY = "./termsource/origin//locality[@type = 'clause']/"\
        "referenceFrom".freeze

      def init_iev
        return nil if @no_isobib
        return @iev if @iev
        @iev = Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        xmldoc.xpath("//term").each do |t|
          /^IEC 60050-/.match(t&.at("./termsource/origin/@citeas")&.text) &&
            loc = t.xpath(SOURCELOCALITY)&.text or next
          @iev = init_iev or return
          iev = @iev.fetch(loc, xmldoc&.at("//language")&.text || "en") or next
          pref = t.xpath("./preferred").inject([]) do |m, x|
            m << x&.text&.downcase
          end
          pref.include?(iev.downcase) or
            @log.add("Bibliography", t, %(Term "#{pref[0]}" does not match ) +
                     %(IEV #{loc} "#{iev}"))
        end
      end

      def content_validate(doc)
        section_validate(doc)
        norm_ref_validate(doc)
        repeat_id_validate(doc.root)
        iev_validate(doc.root)
      end

      def norm_ref_validate(doc)
        found = false
        doc.xpath("//references[@normative = 'true']/bibitem").each do |b|
          next unless docid = b.at("./docidentifier[@type = 'metanorma']")
          next unless  /^\[\d+\]$/.match(docid.text)
          @log.add("Bibliography", b, "Numeric reference in normative references")
          found = true
        end
        if found
          clean_exit
          abort("Numeric reference in normative references")
        end
      end

      def repeat_id_validate1(ids, x)
        if ids[x["id"]]
          @log.add("Anchors", x, "Anchor #{x['id']} has already been used "\
                   "at line #{ids[x['id']]}")
          raise StandardError.new "Error: multiple instances of same ID"
        else
          ids[x["id"]] = x.line
        end
        ids
      end

      def repeat_id_validate(doc)
        ids = {}
        begin
          doc.xpath("//*[@id]").each do |x|
            ids = repeat_id_validate1(ids, x)
          end
        rescue StandardError => e
          clean_exit
          abort(e.message)
        end
      end

      def schema_validate(doc, schema)
        Tempfile.open(["tmp", ".xml"], :encoding => 'UTF-8') do |f|
          begin
            f.write(doc.to_xml) 
            f.close
            errors = Jing.new(schema).validate(f.path)
            warn "Syntax Valid!" if errors.none?
            errors.each do |e|
              @log.add("Metanorma XML Syntax",
                       "XML Line #{"%06d" % e[:line]}:#{e[:column]}",
                       e[:message])
            end
          rescue Jing::Error => e
            clean_exit
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
                  "//bibitem/abstract | //bibitem/note | //misc-container").each do |n|
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
