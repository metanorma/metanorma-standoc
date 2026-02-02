module Metanorma
  module Standoc
    module Base
      def flex_attr_name(node, attr)
        node.attr(attr) || node.attr(attr.sub("pdf-", "pdf")) ||
          node.attr(attr.delete("-").sub(/override$/, "-override")) ||
          node.attr(attr.delete("-").sub(/override$/, "_override"))
      end

      def html_extract_attributes(node)
        i18nyaml = i18nyaml_path(node)
        relaton_render_config = relaton_render_path(node)
        {
          script: flex_attr_name(node, "script"),
          bodyfont: flex_attr_name(node, "body-font"),
          headerfont: flex_attr_name(node, "header-font"),
          monospacefont: flex_attr_name(node, "monospace-font"),
          i18nyaml: i18nyaml,
          relatonrenderconfig: relaton_render_config,
          scope: flex_attr_name(node, "scope"),
          htmlstylesheet: flex_attr_name(node, "html-stylesheet"),
          htmlstylesheet_override: flex_attr_name(node,
                                                  "html-stylesheet-override"),
          htmlcoverpage: flex_attr_name(node, "html-coverpage"),
          htmlintropage: flex_attr_name(node, "html-intropage"),
          scripts: flex_attr_name(node, "scripts"),
          scripts_override: flex_attr_name(node, "scripts-override"),
          scripts_pdf: flex_attr_name(node, "scripts-pdf"),
          datauriimage: flex_attr_name(node, "data-uri-image") != "false",
          htmltoclevels: @htmltoclevels,
          doctoclevels: @doctoclevels,
          pdftoclevels: @pdftoclevels,
          breakupurlsintables: flex_attr_name(node, "break-up-urls-in-tables"),
          suppressasciimathdup: flex_attr_name(node,
                                               "suppress-asciimath-dup") == "true",
          bare: flex_attr_name(node, "bare"),
          sectionsplit: flex_attr_name(node, "sectionsplit"),
          sectionsplit_filename: flex_attr_name(node, "sectionsplit-filename"),
          baseassetpath: flex_attr_name(node, "base-asset-path"),
          aligncrosselements: flex_attr_name(node, "align-cross-elements"),
          tocfigures: @tocfigures,
          toctables: @toctables,
          tocrecommendations: @tocrecommendations,
          fonts: flex_attr_name(node, "fonts"),
          fontlicenseagreement: flex_attr_name(node, "font-license-agreement"),
          localizenumber: flex_attr_name(node, "localize-number"),
          modspecidentifierbase: flex_attr_name(node,
                                                "modspec-identifier-base"),
          sourcehighlighter: flex_attr_name(node,
                                            "source-highlighter") != "false",
        }
      end

      def html_converter(node)
        IsoDoc::HtmlConvert.new(html_extract_attributes(node))
      end

      def pdf_converter(node)
        return nil if flex_attr_name(node, "no-pdf")

        IsoDoc::Standoc::PdfConvert.new(pdf_extract_attributes(node))
      end

      def doc_extract_attributes(node)
        i18nyaml = i18nyaml_path(node)
        relaton_render_config = relaton_render_path(node)
        attrs = {
          script: flex_attr_name(node, "script"),
          bodyfont: flex_attr_name(node, "body-font"),
          headerfont: flex_attr_name(node, "header-font"),
          monospacefont: flex_attr_name(node, "monospace-font"),
          i18nyaml: i18nyaml,
          relatonrenderconfig: relaton_render_config,
          scope: flex_attr_name(node, "scope"),
          wordstylesheet: flex_attr_name(node, "word-stylesheet"),
          wordstylesheet_override: flex_attr_name(node,
                                                  "word-stylesheet-override"),
          standardstylesheet: flex_attr_name(node, "standard-stylesheet"),
          header: flex_attr_name(node, "header"),
          wordcoverpage: flex_attr_name(node, "wordcoverpage"),
          wordintropage: flex_attr_name(node, "wordintropage"),
          ulstyle: flex_attr_name(node, "ulstyle"),
          olstyle: flex_attr_name(node, "olstyle"),
          htmltoclevels: @htmltoclevels,
          doctoclevels: @doctoclevels,
          pdftoclevels: @pdftoclevels,
          breakupurlsintables: flex_attr_name(node, "break-up-urls-in-tables"),
          suppressasciimathdup: flex_attr_name(node, "suppress-asciimath-dup"),
          bare: flex_attr_name(node, "bare"),
          baseassetpath: flex_attr_name(node, "base-asset-path"),
          aligncrosselements: flex_attr_name(node, "align-cross-elements"),
          tocfigures: @tocfigures,
          toctables: @toctables,
          tocrecommendations: @tocrecommendations,
          fonts: flex_attr_name(node, "fonts"),
          fontlicenseagreement: flex_attr_name(node, "font-license-agreement"),
        }

        if fonts_manifest = node.attr(FONTS_MANIFEST)
          attrs[IsoDoc::XslfoPdfConvert::MN2PDF_FONT_MANIFEST] = fonts_manifest
        end

        attrs
      end

      def pdf_extract_attributes(node)
        pdf_options = %w(pdf-encrypt pdf-encryption-length pdf-user-password
                         pdf-owner-password pdf-allow-copy-content
                         pdf-allow-edit-content pdf-allow-fill-in-forms
                         pdf-allow-assemble-document pdf-allow-edit-annotations
                         pdf-allow-print pdf-allow-print-hq pdfkeystore
                         pdfkeystorepassword
                         pdf-allow-access-content pdf-encrypt-metadata fonts
                         pdf-stylesheet pdf-stylesheet-override pdf-portfolio
                         font-license-agreement).each_with_object({}) do |x, m|
          m[x.delete("-").sub(/override$/, "_override").to_sym] =
            flex_attr_name(node, x)
        end
        absolute_path_pdf_attributes(pdf_options)
        pdf_options.merge(fonts_manifest_option(node) || {})
      end

      def absolute_path_pdf_attributes(pdf_options)
        %i(pdfstylesheet pdfstylesheet_override).each do |x|
          pdf_options[x] or next
          (Pathname.new pdf_options[x]).absolute? or
            pdf_options[x] =
              File.join(File.expand_path(@localdir), pdf_options[x])
        end
      end

      def doc_converter(node)
        IsoDoc::WordConvert.new(doc_extract_attributes(node))
      end

      def presentation_xml_converter(node)
        IsoDoc::PresentationXMLConvert
          .new(html_extract_attributes(node)
          .merge(output_formats: ::Metanorma::Standoc::Processor.new
          .output_formats))
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

      def fonts_manifest_option(node)
        if node.attr(FONTS_MANIFEST)
          { mn2pdf: { font_manifest: node.attr(FONTS_MANIFEST) } }
        end
      end
    end
  end
end
