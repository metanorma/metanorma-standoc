require "asciidoctor/iso/utils"
require_relative "./validate_section.rb"
require "nokogiri"
require "jing"
require "pp"
require "iev"

module Asciidoctor
  module Standoc
    module Validate

      SOURCELOCALITY = ".//locality[@type = 'clause']/referenceFrom".freeze

      def iev_validate(xmldoc)
        xmldoc.xpath("//term").each do |t|
          /^IEV($|\s|:)/.match(t&.at(".//origin/@citeas")&.text) or next
          pref = t.xpath("./preferred").inject([]) { |m, x| m << x&.text&.downcase }
          locality = t.xpath(SOURCELOCALITY)&.text or next
          iev = @iev.fetch(locality, xmldoc&.at("//language")&.text || "en") or next
          pref.include?(iev.downcase) or
            warn %(Term "#{pref[0]}" does not match IEV #{locality} "#{iev}")
        end
      end

      def content_validate(doc)
        section_validate(doc)
        iev_validate(doc.root)
      end

      def schema_validate(doc, filename)
        File.open(".tmp.xml", "w:UTF-8") { |f| f.write(doc.to_xml) }
        begin
          errors = Jing.new(filename).validate(".tmp.xml")
        rescue Jing::Error => e
          abort "what what what #{e}"
        end
        warn "Valid!" if errors.none?
        errors.each do |error|
          warn "#{error[:message]} @ #{error[:line]}:#{error[:column]}"
        end
      end

      # RelaxNG cannot cope well with wildcard attributes. So we strip
      # any attributes from FormattedString instances (which can contain
      # xs:any markup, and are signalled with @format) before validation.
      def formattedstr_strip(doc)
        doc.xpath("//*[@format]").each do |n|
          n.elements.each do |e|
            e.traverse do |e1|
              next unless e1.element?
              e1.each { |k, _v| e.delete(k) }
            end
          end
        end
        doc
      end

      def validate(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup),
                        File.join(File.dirname(__FILE__), "isostandard.rng"))
      end
    end
  end
end
