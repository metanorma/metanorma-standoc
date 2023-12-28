require "metanorma/standoc/utils"
require_relative "validate_section"
require_relative "validate_table"
require_relative "validate_term"
require "nokogiri"
require "jing"
require "iev"
require "pngcheck"

module Metanorma
  module Standoc
    module Validate
      def content_validate(doc)
        @doctype = doc.at("//bibdata/ext/doctype")&.text
        repeat_id_validate(doc.root) # feeds xref_validate
        xref_validate(doc) # feeds nested_asset_validate
        nested_asset_validate(doc)
        section_validate(doc)
        norm_ref_validate(doc)
        iev_validate(doc.root)
        concept_validate(doc, "concept", "refterm")
        concept_validate(doc, "related", "preferred//name")
        preferred_validate(doc)
        table_validate(doc)
        requirement_validate(doc)
        image_validate(doc)
        math_validate(doc)
        fatalerrors = @log.abort_messages
        fatalerrors.empty? or
          clean_abort(fatalerrors.join("\n"), doc)
      end

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def math_validate(doc)
        doc.xpath("//m:math", "m" => MATHML_NS).each do |m|
          math = mathml_sanitise(m.dup)
          Plurimath::Math.parse(math, "mathml").to_mathml
        rescue StandardError => e
          math_validate_error(math, m, e)
        end
      end

      def mathml_sanitise(math)
        math.to_xml(encoding: "US-ASCII").gsub(/ xmlns=["'][^"']+["']/, "")
          .gsub(%r{<[^:/>]+:}, "<").gsub(%r{</[^:/>]+:}, "</")
        # .gsub(/&#([^;]+);/) { |x| "&#x#{$1.to_i.to_s(16)};" }
      end

      def math_validate_error(math, elem, error)
        a = elem.parent.at("./asciimath")
        l = elem.parent.at("./latexmath")
        orig = ""
        a and orig += "\n\tAsciimath original: #{@c.decode(a.children.to_xml)}"
        l and orig += "\n\tLatexmath original: #{@c.decode(l.children.to_xml)}"
        @log.add("Mathematics", elem,
                 "Invalid MathML: #{math}\n #{error}#{orig}", severity: 0)
      end

      def nested_asset_validate(doc)
        nested_asset_validate_basic(doc)
        nested_note_validate(doc)
      end

      def nested_asset_validate_basic(doc)
        a = "//example | //figure | //termnote | //termexample | //table"
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

      def image_validate(doc)
        image_exists(doc)
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

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "isodoc-compile.rng"))
      end

      def repeat_id_validate1(elem)
        if @doc_ids[elem["id"]]
          @log.add("Anchors", elem,
                   "Anchor #{elem['id']} has already been " \
                   "used at line #{@doc_ids[elem['id']]}", severity: 0)
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
                   "Crossreference target #{x} is undefined", severity: 1)
        end
      end
    end
  end
end
