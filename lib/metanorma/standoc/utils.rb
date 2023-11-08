require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "uuidtools"

module Metanorma
  module Standoc
    module Utils
      def convert(node, transform = nil, opts = {})
        transform ||= node.node_name
        opts.empty? ? (send transform, node) : (send transform, node, opts)
      end

      def document_ns_attributes(_doc)
        nil
      end

      def noko(&block)
        Metanorma::Utils::noko(@script, &block)
      end

      def attr_code(attributes)
        Metanorma::Utils::attr_code(attributes)
      end

      def csv_split(text, delim = ";")
        Metanorma::Utils::csv_split(text, delim)
      end

      def wrap_in_para(node, out)
        Metanorma::Utils::wrap_in_para(node, out)
      end

      def to_xml(node)
        node.to_xml(encoding: "UTF-8", indent: 2,
                    save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      SUBCLAUSE_XPATH = "//clause[not(parent::sections)]" \
                        "[not(ancestor::boilerplate)]".freeze

      def isodoc(lang, script, locale, i18nyaml = nil)
        conv = presentation_xml_converter(EmptyAttr.new)
        i18n = conv.i18n_init(lang, script, locale, i18nyaml)
        conv.metadata_init(lang, script, locale, i18n)
        conv
      end

      def dl_to_attrs(elem, dlist, name)
        Metanorma::Utils::dl_to_attrs(elem, dlist, name)
      end

      def dl_to_elems(ins, elem, dlist, name)
        Metanorma::Utils::dl_to_elems(ins, elem, dlist, name)
      end

      def term_expr(elem)
        "<expression><name>#{elem}</name></expression>"
      end

      def link_unwrap(para)
        elems = para.elements
        if elems.size == 1 && elems[0].name == "link"
          para.at("./link").replace(elems[0]["target"].strip)
        end
        para
      end

      def xml_encode(text)
        @c.encode(text, :basic, :hexadecimal).
          gsub("&amp;gt;", ">").gsub("&amp;lt;", "<").gsub("&amp;amp;", "&").
          gsub("&gt;", ">").gsub("&lt;", "<").gsub("&amp;", "&").
          gsub("&quot;", '"').gsub("&#xa;", "\n").gsub("&amp;#", "&#").
          gsub("&apos;", "'")
      end

      # wrapped in <sections>
      def adoc2xml(text, flavour)
        Nokogiri::XML(text).root and return text
        c = Asciidoctor.convert("= X\nA\n:semantic-metadata-headless: true\n" \
                                ":novalid:\n\n#{text}\n",
                                backend: flavour, header_footer: true)
        Nokogiri::XML(c).at("//xmlns:sections")
      end

      def asciimath_key(sym)
        key = sym.dup
        key.traverse do |n|
          if n.name == "stem" && a = n.at(".//asciimath")
            n.children = @c.encode(
              @c.decode(grkletters(a.text)), :basic
            )
          end
        end
        key.xpath(".//asciimath").each(&:remove)
        Nokogiri::XML(key.to_xml)
      end

      def grkletters(text)
        text.gsub(/\b(alpha|beta|gamma|delta|epsilon|zeta|eta|theta|iota|kappa|
                      lambda|mu|nu|xi|omicron|pi|rho|sigma|tau|upsilon|phi|chi|
                      psi|omega)\b/xi, "&\\1;")
      end

      def refid?(ref)
        @refids.include? ref
      end

      module_function :adoc2xml

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
