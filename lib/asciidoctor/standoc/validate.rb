require "asciidoctor/standoc/utils"
require_relative "./validate_section"
require "nokogiri"
require "jing"
require "iev"

module Asciidoctor
  module Standoc
    module Validate
      SOURCELOCALITY = "./origin//locality[@type = 'clause']/"\
                       "referenceFrom".freeze

      def init_iev
        return nil if @no_isobib
        return @iev if @iev

        @iev = Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        @iev = init_iev or return
        xmldoc.xpath("//term").each do |t|
          t.xpath(".//termsource").each do |src|
            (/^IEC 60050-/.match(src&.at("./origin/@citeas")&.text) &&
          loc = src.xpath(SOURCELOCALITY)&.text) or next
            iev_validate1(t, loc, xmldoc)
          end
        end
      end

      def iev_validate1(term, loc, xmldoc)
        iev = @iev.fetch(loc,
                         xmldoc&.at("//language")&.text || "en") or return
        pref = term.xpath("./preferred//name").inject([]) do |m, x|
          m << x&.text&.downcase
        end
        pref.include?(iev.downcase) or
          @log.add("Bibliography", term, %(Term "#{pref[0]}" does not match ) +
                   %(IEV #{loc} "#{iev}"))
      end

      def content_validate(doc)
        @fatalerror = []
        xref_validate(doc)
        section_validate(doc)
        norm_ref_validate(doc)
        repeat_id_validate(doc.root)
        iev_validate(doc.root)
        concept_validate(doc, "concept", "refterm")
        concept_validate(doc, "related", "preferred//name")
        @fatalerror.empty? or clean_abort(@fatalerror.join("\n"), doc.to_xml)
      end

      def norm_ref_validate(doc)
        found = false
        doc.xpath("//references[@normative = 'true']/bibitem").each do |b|
          next unless docid = b.at("./docidentifier[@type = 'metanorma']")
          next unless /^\[\d+\]$/.match?(docid.text)

          @log.add("Bibliography", b,
                   "Numeric reference in normative references")
          found = true
        end
        found and @fatalerror << "Numeric reference in normative references"
      end

      def concept_validate(doc, tag, refterm)
        found = false
        doc.xpath("//#{tag}/xref").each do |x|
          next if doc.at("//term[@id = '#{x['target']}']")
          next if doc.at("//definitions//dt[@id = '#{x['target']}']")

          ref = x&.at("../#{refterm}")&.text
          @log.add("Anchors", x,
                   "#{tag.capitalize} #{ref} is pointing to "\
                   "#{x['target']}, which is not a term or symbol")
          found = true
        end
        found and
          @fatalerror << "#{tag.capitalize} not cross-referencing term or symbol"
      end

      def repeat_id_validate1(ids, elem)
        if ids[elem["id"]]
          @log.add("Anchors", elem, "Anchor #{elem['id']} has already been "\
                                    "used at line #{ids[elem['id']]}")
          @fatalerror << "Multiple instances of same ID: #{elem['id']}"
        else
          ids[elem["id"]] = elem.line
        end
        ids
      end

      def repeat_id_validate(doc)
        ids = {}
        doc.xpath("//*[@id]").each do |x|
          ids = repeat_id_validate1(ids, x)
        end
      end

      def schema_validate(doc, schema)
        Tempfile.open(["tmp", ".xml"], encoding: "UTF-8") do |f|
          schema_validate1(f, doc, schema)
        rescue Jing::Error => e
          clean_abort("Jing failed with error: #{e}", doc.to_xml)
        ensure
          f.close!
        end
      end

      def schema_validate1(file, doc, schema)
        file.write(doc.to_xml)
        file.close
        errors = Jing.new(schema).validate(file.path)
        warn "Syntax Valid!" if errors.none?
        errors.each do |e|
          @log.add("Metanorma XML Syntax",
                   "XML Line #{'%06d' % e[:line]}:#{e[:column]}", e[:message])
        end
      end

      # RelaxNG cannot cope well with wildcard attributes. So we strip
      # any attributes from FormattedString instances (which can contain
      # xs:any markup, and are signalled with @format) before validation.
      def formattedstr_strip(doc)
        doc.xpath("//*[@format] | //stem | //bibdata//description | "\
                  "//formattedref | //bibdata//note | //bibdata/abstract | "\
                  "//bibitem/abstract | //bibitem/note | //misc-container")
          .each do |n|
          n.elements.each do |e|
            e.traverse do |e1|
              e1.element? and e1.each { |k, _v| e1.delete(k) }
            end
          end
        end
        doc
      end

      # manually check for xref/@target, xref/@to integrity
      def xref_validate(doc)
        ids = doc.xpath("//*/@id").each_with_object({}) { |x, m| m[x.text] = 1 }
        doc.xpath("//xref/@target | //xref/@to").each do |x|
          next if ids[x.text]

          @log.add("Anchors", x.parent,
                   "Crossreference target #{x.text} is undefined")
        end
      end

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "isodoc.rng"))
      end
    end
  end
end
