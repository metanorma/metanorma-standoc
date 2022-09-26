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
        Metanorma::Utils::noko(&block)
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

      SUBCLAUSE_XPATH = "//clause[not(parent::sections)]"\
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
