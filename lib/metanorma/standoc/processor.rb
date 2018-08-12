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
        "Asciidoctor::Standoc #{Metanorma::Standoc::VERSION}/IsoDoc #{IsoDoc::VERSION}"
      end

      def input_to_isodoc(file)
        Metanorma::Input::Asciidoc.new.process(file, @asciidoctor_backend)
      end

      def output(isodoc_node, outname, format, options={})
        case format
        when :html
          IsoDoc::HtmlConvert.new(options).convert(outname, isodoc_node)
        when :doc
          IsoDoc::WordConvert.new(options).convert(outname, isodoc_node)
        else
          super
        end
      end
    end
  end
end
