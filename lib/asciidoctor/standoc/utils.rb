require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "uuidtools"

module Asciidoctor
  module Standoc
    module Utils
      def convert(node, transform = nil, opts = {})
        transform ||= node.node_name
        opts.empty? ? (send transform, node) : (send transform, node, opts)
      end

      def document_ns_attributes(_doc)
        nil
      end

      NOKOHEAD = <<~HERE.freeze
        <!DOCTYPE html SYSTEM
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head> <title></title> <meta charset="UTF-8" /> </head>
        <body> </body> </html>
      HERE

      # block for processing XML document fragments as XHTML,
      # to allow for HTMLentities
      # Unescape special chars used in Asciidoctor substitution processing
      def noko(&block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment.to_xml(encoding: "US-ASCII", indent: 0).lines.map do |l|
          l.gsub(/>\n$/, ">").gsub(/\s*\n$/m, " ").gsub("&#150;", "\u0096").
            gsub("&#151;", "\u0097").gsub("&#x96;", "\u0096").
            gsub("&#x97;", "\u0097")
        end
      end

      def attr_code(attributes)
        attributes = attributes.reject { |_, val| val.nil? }.map
        attributes.map do |k, v|
          [k, (v.is_a? String) ? HTMLEntities.new.decode(v) : v]
        end.to_h
      end

      # if the contents of node are blocks, output them to out;
      # else, wrap them in <p>
      def wrap_in_para(node, out)
        if node.blocks? then out << node.content
        else
          out.p { |p| p << node.content }
        end
      end

      SUBCLAUSE_XPATH = "//clause[not(parent::sections)]"\
        "[not(ancestor::boilerplate)]".freeze

      def isodoc(lang, script, i18nyaml = nil)
        conv = html_converter(EmptyAttr.new)
        i18n = conv.i18n_init(lang, script, i18nyaml)
        conv.metadata_init(lang, script, i18n)
        conv
      end

      def default_script(lang)
        case lang
        when "ar", "fa"
          "Arab"
        when "ur"
          "Aran"
        when "ru", "bg"
          "Cyrl"
        when "hi"
          "Deva"
        when "el"
          "Grek"
        when "zh"
          "Hans"
        when "ko"
          "Kore"
        when "he"
          "Hebr"
        when "ja"
          "Jpan"
        else
          "Latn"
        end
      end

      class EmptyAttr
        def attr(_any_attribute)
          nil
        end

        def attributes
          {}
        end
      end
    end
  end
end
