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

      def processor
        parent_type = self.class.name.split("::")[0...-1]
        parent_type << "Processor"
        begin
          Object.const_get(parent_type.join("::"))
        rescue NameError
          nil
        end
      end

      def document_ns_attributes(_doc)
        nil
      end

      def noko(&)
        Metanorma::Utils::noko(@script, &)
      end

      def attr_code(attributes)
        Metanorma::Utils::attr_code(attributes)
      end

      def csv_split(text, delim = ";")
        Metanorma::Utils::csv_split(@c.decode(text), delim)
          .map { |x| @c.encode(x, :basic, :hexadecimal) }
      end

      # quoted strings: key="va,lue",
      def quoted_csv_split(text, delim = ",", eql = "=")
        c = HTMLEntities.new
        text = c.decode(text).gsub(/([a-zA-Z_]+)#{eql}(["'])(.*?)\2/) do |_|
          key = Regexp.last_match(1)
          value = Regexp.last_match(3).gsub(" ", "&#x20;")
          "\"#{key}#{eql}#{value}\""
        end
        Metanorma::Utils::csv_split(text, delim).map do |x|
          c.encode(x.sub(/^(["'])(.*?)\1$/, "\\2"),
                   :basic, :hexadecimal)
        end
      end

      def kv_parse(text, delim = ",", eql = "=")
        text or return {}
        c = HTMLEntities.new
        quoted_csv_split(text, delim).each_with_object({}) do |k, m|
          x = k.split(eql, 2)
          m[x[0]] = c.decode(x[1])
        end
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

      def insert_before(xmldoc, xpath)
        unless ins = xmldoc.at(xpath).children.first
          xmldoc.at(xpath) << " "
          ins = xmldoc.at(xpath).children.first
        end
        ins
      end

      def xml_encode(text)
        @c.encode(text, :basic, :hexadecimal)
          .gsub("&amp;gt;", ">").gsub("&amp;lt;", "<").gsub("&amp;amp;", "&")
          .gsub("&gt;", ">").gsub("&lt;", "<").gsub("&amp;", "&")
          .gsub("&quot;", '"').gsub("&#xa;", "\n").gsub("&amp;#", "&#")
          .gsub("&apos;", "'")
      end

      IDREF =
        [%w(review from), %w(review to), %w(callout target), %w(eref bibitemid),
         %w(citation bibitemid), %w(xref target), %w(xref to), %w(label for),
         %w(location target), %w(index to), %w(termsource bibitemid)].freeze

      SECTION_CONTAINERS =
        %w(foreword introduction acknowledgements executivesummary abstract
           clause references terms definitions annex appendix indexsect
           executivesummary).freeze

      def section_containers
        SECTION_CONTAINERS
      end

      # wrapped in <sections>
      def adoc2xml(text, flavour)
        Nokogiri::XML(text).root and return text
        f = @flush_caches ? ":flush-caches:\n" : ""
        doc = <<~ADOC
          = X
          A
          :semantic-metadata-headless: true
          :no-isobib:
          #{f}:novalid:
          :!sectids:

          #{text}
        ADOC
        c = Asciidoctor.convert(doc, backend: flavour, header_footer: true)
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

      def uuid?(ref)
        /^_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
          .match?(ref)
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
