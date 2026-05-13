require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "uuidtools"
require "metanorma-core"
require_relative "../../nokogiri/xml/builder"
require_relative "date_utils"

module Metanorma
  module Standoc
    module Utils
      include ::Metanorma::Core::Boilerplate

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

      def add_id(node)
        node["id"] = "_#{UUIDTools::UUID.random_create}"
      end

      def add_id_text
        %(id = "_#{UUIDTools::UUID.random_create}")
      end

      def csv_split(text, delim = ";", encode: true)
        text ||= ""
        ret = Metanorma::Utils::csv_split(@c.decode(text), delim)
        encode and
          ret.map! { |x| @c.encode(x.strip, :basic, :hexadecimal) }
        ret
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
        Metanorma::Core::Isodoc.init(conv, lang: lang, script: script,
                                           locale: locale, i18nyaml: i18nyaml,
                                           localdir: @localdir)
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

      SECTION_CONTAINERS =
        %w(foreword introduction acknowledgements executivesummary abstract
           clause references terms definitions annex appendix indexsect
           executivesummary).freeze

      def section_containers
        SECTION_CONTAINERS
      end

      # Shadow metanorma-core's adoc2xml so the standoc converter context
      # gets externally-sourced footnotes renumbered automatically
      # (preserving the existing direct-caller behaviour: process_boilerplate_file
      # in cleanup, header conversion in dochistory).
      def adoc2xml(text, flavour, flush_caches: false, localdir: nil)
        ret = super
        ret.is_a?(Nokogiri::XML::Node) ? separate_numbering_footnotes(ret) : ret
      end

      # separate numbering of externally sourced footnotes
      # from that of current doc
      def separate_numbering_footnotes(docxml)
        docxml.xpath("//xmlns:fn").each do |f|
          f["reference"] = "_#{UUIDTools::UUID.random_create}_#{f['reference']}"
        end
        docxml
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

      def add_noko_elem(node, name, val, attrs = {})
        (val and !val.empty?) or return
        node.send name, **attr_code(attrs) do |n|
          n << val
        end
      end

      def textcleanup(result)
        text = result.flatten.map(&:rstrip) * "\n"
        text.gsub(/(?<!\s)\s+<fn /, "<fn ")
      end
    end

    EmptyAttr = Metanorma::Core::Isodoc::EmptyNode
  end
end
