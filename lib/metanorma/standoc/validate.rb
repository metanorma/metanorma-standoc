require "metanorma/standoc/utils"
require_relative "./validate_section"
require_relative "./validate_table"
require "nokogiri"
require "jing"
require "iev"
require "pngcheck"

module Metanorma
  module Standoc
    module Validate
      SOURCELOCALITY = "./origin//locality[@type = 'clause']/" \
                       "referenceFrom".freeze

      def init_iev
        @no_isobib and return nil
        @iev and return @iev
        @iev = Iev::Db.new(@iev_globalname, @iev_localname) unless @no_isobib
        @iev
      end

      def iev_validate(xmldoc)
        @iev = init_iev or return
        xmldoc.xpath("//term").each do |t|
          t.xpath(".//termsource").each do |src|
            (/^IEC[  ]60050-/.match(src.at("./origin/@citeas")&.text) &&
          loc = src.xpath(SOURCELOCALITY)&.text) or next
            iev_validate1(t, loc, xmldoc)
          end
        end
      end

      def iev_validate1(term, loc, xmldoc)
        iev = @iev.fetch(loc,
                         xmldoc.at("//language")&.text || "en") or return
        pref = term.xpath("./preferred//name").inject([]) do |m, x|
          m << x.text&.downcase
        end
        pref.include?(iev.downcase) or
          @log.add("Bibliography", term, %(Term "#{pref[0]}" does not match ) +
                   %(IEV #{loc} "#{iev}"))
      end

      def content_validate(doc)
        repeat_id_validate(doc.root) # feeds xref_validate
        xref_validate(doc) # feeds nested_asset_validate
        nested_asset_validate(doc)
        section_validate(doc)
        norm_ref_validate(doc)
        iev_validate(doc.root)
        concept_validate(doc, "concept", "refterm")
        concept_validate(doc, "related", "preferred//name")
        table_validate(doc)
        @fatalerror += requirement_validate(doc)
        image_validate(doc)
        @fatalerror.empty? or
          clean_abort(@fatalerror.join("\n"), doc)
      end

      def nested_asset_validate(doc)
        nested_asset_validate_basic(doc)
        nested_note_validate(doc)
      end

      def nested_asset_validate_basic(doc)
        a = "//formula | //example | //figure | //termnote | //termexample | " \
            "//table"
        doc.xpath("#{a} | //note").each do |m|
          m.xpath(a.gsub(%r{//}, ".//")).each do |n|
            nested_asset_report(m, n, doc)
          end
        end
      end

      def nested_note_validate(doc)
        doc.xpath("//termnote | //note").each do |m|
          m.xpath(".//note").each do |n|
            nested_asset_report(m, n, doc)
          end
        end
      end

      def nested_asset_report(outer, inner, doc)
        outer.name == "figure" && inner.name == "figure" and return
        outer.name != "formula" && inner.name == "formula" and return
        err =
          "There is an instance of #{inner.name} nested within #{outer.name}"
        @log.add("Syntax", inner, err)
        nested_asset_xref_report(outer, inner, doc)
      end

      def nested_asset_xref_report(outer, inner, _doc)
        i = @doc_xrefs[inner["id"]] or return
        err2 = "There is a crossreference to an instance of #{inner.name} " \
               "nested within #{outer.name}: #{i.to_xml}"
        @log.add("Style", i, err2)
        @fatalerror << err2
      end

      def norm_ref_validate(doc)
        found = false
        doc.xpath("//references[@normative = 'true']/bibitem").each do |b|
          docid = b.at("./docidentifier[@type = 'metanorma']") or next
          /^\[\d+\]$/.match?(docid.text) or next
          @log.add("Bibliography", b,
                   "Numeric reference in normative references")
          found = true
        end
        found and @fatalerror << "Numeric reference in normative references"
      end

      def concept_validate(doc, tag, refterm)
        found = false
        concept_validate_ids(doc)
        doc.xpath("//#{tag}/xref").each do |x|
          @concept_ids[x["target"]] and next
          @log.add("Anchors", x, concept_validate_msg(doc, tag, refterm, x))
          found = true
        end
        found and @fatalerror << "#{tag.capitalize} not cross-referencing " \
                                 "term or symbol"
      end

      def concept_validate_ids(doc)
        @concept_ids ||= doc.xpath("//term | //definitions//dt")
          .each_with_object({}) { |x, m| m[x["id"]] = true }
        @concept_terms_tags ||= doc.xpath("//terms")
          .each_with_object({}) { |t, m| m[t["id"]] = true }
        nil
      end

      def concept_validate_msg(_doc, tag, refterm, xref)
        ret = <<~LOG
          #{tag.capitalize} #{xref.at("../#{refterm}")&.text} is pointing to #{xref['target']}, which is not a term or symbol
        LOG
        if @concept_terms_tags[xref["target"]]
          ret = ret.strip
          ret += ". Did you mean to point to a subterm?"
        end
        ret
      end

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

      def schema_validate(doc, schema)
        Tempfile.open(["tmp", ".xml"], encoding: "UTF-8") do |f|
          schema_validate1(f, doc, schema)
        rescue Jing::Error => e
          clean_abort("Jing failed with error: #{e}", doc)
        ensure
          f.close!
        end
      end

      def schema_validate1(file, doc, schema)
        file.write(to_xml(doc))
        file.close
        errors = Jing.new(schema, encoding: "UTF-8").validate(file.path)
        warn "Syntax Valid!" if errors.none?
        errors.each do |e|
          @log.add("Metanorma XML Syntax",
                   "XML Line #{'%06d' % e[:line]}:#{e[:column]}", e[:message])
        end
      end

      SVG_NS = "http://www.w3.org/2000/svg".freeze

      WILDCARD_ATTRS =
        "//*[@format] | //stem | //bibdata//description | " \
        "//formattedref | //bibdata//note | //bibdata/abstract | " \
        "//bibitem/abstract | //bibitem/note | //metanorma-extension".freeze

      # RelaxNG cannot cope well with wildcard attributes. So we strip
      # any attributes from FormattedString instances (which can contain
      # xs:any markup, and are signalled with @format) before validation.
      def formattedstr_strip(doc)
        doc.xpath(WILDCARD_ATTRS, "m" => SVG_NS).each do |n|
          n.elements.each do |e|
            e.traverse do |e1|
              e1.element? and e1.each { |k, _v| e1.delete(k) }
            end
          end
        end
        doc.xpath("//m:svg", "m" => SVG_NS).each { |n| n.replace("<svg/>") }
        doc
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

      def image_validate(doc)
        image_exists(doc)
        png_validate(doc)
      end

      def image_exists(doc)
        doc.xpath("//image").each do |i|
          Metanorma::Utils::url?(i["src"]) and next
          Metanorma::Utils::datauri?(i["src"]) and next
          expand_path(i["src"]) and next
          @log.add("Images", i.parent,
                   "Image not found: #{i['src']}")
          @fatalerror << "Image not found: #{i['src']}"
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
          Metanorma::Utils::url?(i["src"]) and next
          decoded = if Metanorma::Utils::datauri?(i["src"])
                      Metanorma::Utils::decode_datauri(i["src"])[:data]
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

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "isodoc-compile.rng"))
      end
    end
  end
end
