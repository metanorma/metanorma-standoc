require "metanorma/processor"

module Metanorma
  module Standoc
    class Processor < Metanorma::Processor

      def initialize
        @short = :standoc
        @input_format = :asciidoc
        @asciidoctor_backend = :standoc
      end

      def output_formats
        super.merge(
          html: "html",
          doc: "doc"
        )
      end

      def version
        "Metanorma::Standoc #{Metanorma::Standoc::VERSION}/IsoDoc #{IsoDoc::VERSION}"
      end

      def input_to_isodoc(file, filename)
        Metanorma::Input::Asciidoc.new.process(file, filename, @asciidoctor_backend)
      end

      def output(isodoc_node, inname, outname, format, options={})
        case format
        when :html
          IsoDoc::HtmlConvert.new(options).convert(inname, isodoc_node, nil, outname)
        when :doc
          IsoDoc::WordConvert.new(options).convert(inname, isodoc_node, nil, outname)
        when :presentation
          IsoDoc::PresentationXMLConvert.new(options).convert(inname, isodoc_node, nil, outname)
        else
          super
        end
      end
    end
  end
end
