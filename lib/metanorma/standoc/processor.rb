require "metanorma/processor"

module Metanorma
  module Standoc
    class Processor < Metanorma::Processor
      class << self
        attr_reader :asciidoctor_backend
            end

      def initialize # rubocop:disable Lint/MissingSuper
        @short = :standoc
        @input_format = :asciidoc
        @asciidoctor_backend = :standoc
      end

      def output_formats
        super.merge(
          html: "html",
          doc: "doc",
          pdf: "pdf",
        )
      end

      def version
        "Metanorma::Standoc #{Metanorma::Standoc::VERSION}/"\
          "IsoDoc #{IsoDoc::VERSION}"
      end

      def html_path(file)
        File.join(File.dirname(__FILE__), "..", "..", "isodoc", "html",
                  file)
      end

      def output(isodoc_node, inname, outname, format, options = {})
        case format
        when :html
          options = options
            .merge(htmlstylesheet: html_path("htmlstyle.scss"),
                   htmlcoverpage: html_path("html_titlepage.html"))
          IsoDoc::HtmlConvert.new(options)
            .convert(inname, isodoc_node, nil, outname)
        when :doc
          IsoDoc::WordConvert.new(options)
            .convert(inname, isodoc_node, nil, outname)
        when :pdf
          IsoDoc::Standoc::PdfConvert.new(options)
            .convert(inname, isodoc_node, nil, outname)
        when :presentation
          IsoDoc::PresentationXMLConvert.new(options)
            .convert(inname, isodoc_node, nil, outname)
        else
          super
        end
      end
    end
  end
end
