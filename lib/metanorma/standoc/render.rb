module Asciidoctor
  module Standoc
    module Base
      def html_extract_attributes(node)
        {
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          htmlstylesheet: node.attr("htmlstylesheet"),
          htmlstylesheet_override: node.attr("htmlstylesheet-override"),
          htmlcoverpage: node.attr("htmlcoverpage"),
          htmlintropage: node.attr("htmlintropage"),
          scripts: node.attr("scripts"),
          scripts_override: node.attr("scripts-override"),
          scripts_pdf: node.attr("scripts-pdf"),
          datauriimage: node.attr("data-uri-image") != "false",
          htmltoclevels: node.attr("htmltoclevels") || node.attr("toclevels"),
          doctoclevels: node.attr("doctoclevels") || node.attr("toclevels"),
          break_up_urls_in_tables: node.attr("break-up-urls-in-tables"),
          suppressasciimathdup: node.attr("suppress-asciimath-dup"),
          bare: node.attr("bare"),
          sectionsplit: node.attr("sectionsplit"),
          baseassetpath: node.attr("base-asset-path"),
          aligncrosselements: node.attr("align-cross-elements"),
        }
      end

      def html_converter(node)
        IsoDoc::HtmlConvert.new(html_extract_attributes(node))
      end

      def pdf_converter(node)
        return nil if node.attr("no-pdf")

        IsoDoc::Standoc::PdfConvert.new(pdf_extract_attributes(node))
      end

      def doc_extract_attributes(node)
        attrs = {
          script: node.attr("script"),
          bodyfont: node.attr("body-font"),
          headerfont: node.attr("header-font"),
          monospacefont: node.attr("monospace-font"),
          i18nyaml: node.attr("i18nyaml"),
          scope: node.attr("scope"),
          wordstylesheet: node.attr("wordstylesheet"),
          wordstylesheet_override: node.attr("wordstylesheet-override"),
          standardstylesheet: node.attr("standardstylesheet"),
          header: node.attr("header"),
          wordcoverpage: node.attr("wordcoverpage"),
          wordintropage: node.attr("wordintropage"),
          ulstyle: node.attr("ulstyle"),
          olstyle: node.attr("olstyle"),
          htmltoclevels: node.attr("htmltoclevels") || node.attr("toclevels"),
          doctoclevels: node.attr("doctoclevels") || node.attr("toclevels"),
          break_up_urls_in_tables: node.attr("break-up-urls-in-tables"),
          suppressasciimathdup: node.attr("suppress-asciimath-dup"),
          bare: node.attr("bare"),
          baseassetpath: node.attr("base-asset-path"),
          aligncrosselements: node.attr("align-cross-elements"),
        }

        if fonts_manifest = node.attr(FONTS_MANIFEST)
          attrs[IsoDoc::XslfoPdfConvert::MN2PDF_OPTIONS] = {
            IsoDoc::XslfoPdfConvert::MN2PDF_FONT_MANIFEST => fonts_manifest,
          }
        end

        attrs
      end

      def pdf_extract_attributes(node)
        %w(pdf-encrypt pdf-encryption-length pdf-user-password
           pdf-owner-password pdf-allow-copy-content pdf-allow-edit-content
           pdf-allow-assemble-document pdf-allow-edit-annotations
           pdf-allow-print pdf-allow-print-hq pdf-allow-fill-in-forms
           pdf-allow-access-content pdf-encrypt-metadata)
          .each_with_object({}) do |x, m|
          m[x.gsub(/-/, "").to_i] = node.attr(x)
        end
      end

      def doc_converter(node)
        IsoDoc::WordConvert.new(doc_extract_attributes(node))
      end

      def presentation_xml_converter(node)
        IsoDoc::PresentationXMLConvert.new(html_extract_attributes(node))
      end

      def default_fonts(node)
        b = node.attr("body-font") ||
          (node.attr("script") == "Hans" ? '"Source Han Sans",serif' : '"Cambria",serif')
        h = node.attr("header-font") ||
          (node.attr("script") == "Hans" ? '"Source Han Sans",sans-serif' : '"Cambria",serif')
        m = node.attr("monospace-font") || '"Courier New",monospace'
        "$bodyfont: #{b};\n$headerfont: #{h};\n$monospacefont: #{m};\n"
      end

      def outputs(node, ret)
        File.open("#{@filename}.xml", "w:UTF-8") { |f| f.write(ret) }
        presentation_xml_converter(node).convert("#{@filename}.xml")
        html_converter(node).convert("#{@filename}.presentation.xml",
                                     nil, false, "#{@filename}.html")
        doc_converter(node).convert("#{@filename}.presentation.xml",
                                    nil, false, "#{@filename}.doc")
        pdf_converter(node)&.convert("#{@filename}.presentation.xml",
                                     nil, false, "#{@filename}.pdf")
      end
    end
  end
end
