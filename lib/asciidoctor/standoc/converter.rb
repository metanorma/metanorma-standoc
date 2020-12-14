require "asciidoctor"
require "fontist"
require "fontist/manifest/install"
require "metanorma/util"
require "metanorma/standoc/version"
require "asciidoctor/standoc/base"
require "asciidoctor/standoc/front"
require "asciidoctor/standoc/lists"
require "asciidoctor/standoc/ref"
require "asciidoctor/standoc/inline"
require "asciidoctor/standoc/blocks"
require "asciidoctor/standoc/section"
require "asciidoctor/standoc/table"
require "asciidoctor/standoc/validate"
require "asciidoctor/standoc/utils"
require "asciidoctor/standoc/cleanup"
require "asciidoctor/standoc/reqt"
require_relative "./macros.rb"
require_relative "./log.rb"

module Asciidoctor
  module Standoc
    # A {Converter} implementation that generates Standoc output, and a document
    # schema encapsulation of the document for validation
    class Converter
      Asciidoctor::Extensions.register do
        preprocessor Asciidoctor::Standoc::Datamodel::AttributesTablePreprocessor
        preprocessor Asciidoctor::Standoc::Datamodel::DiagramPreprocessor
        preprocessor Metanorma::Plugin::Datastruct::Json2TextPreprocessor
        preprocessor Metanorma::Plugin::Datastruct::Yaml2TextPreprocessor
        preprocessor Metanorma::Plugin::Lutaml::LutamlPreprocessor
        preprocessor Metanorma::Plugin::Lutaml::LutamlUmlAttributesTablePreprocessor
        inline_macro Asciidoctor::Standoc::AltTermInlineMacro
        inline_macro Asciidoctor::Standoc::DeprecatedTermInlineMacro
        inline_macro Asciidoctor::Standoc::DomainTermInlineMacro
        inline_macro Asciidoctor::Standoc::InheritInlineMacro
        inline_macro Asciidoctor::Standoc::HTML5RubyMacro
        inline_macro Asciidoctor::Standoc::ConceptInlineMacro
        inline_macro Asciidoctor::Standoc::AutonumberInlineMacro
        inline_macro Asciidoctor::Standoc::VariantInlineMacro
        inline_macro Asciidoctor::Standoc::FootnoteBlockInlineMacro
        inline_macro Asciidoctor::Standoc::TermRefInlineMacro
        inline_macro Asciidoctor::Standoc::IndexInlineMacro
        block Asciidoctor::Standoc::ToDoAdmonitionBlock
        treeprocessor Asciidoctor::Standoc::ToDoInlineAdmonitionBlock
        block Asciidoctor::Standoc::PlantUMLBlockMacro
        block Metanorma::Plugin::Lutaml::LutamlDiagramBlock
        block Asciidoctor::Standoc::PseudocodeBlockMacro
      end

      include ::Asciidoctor::Converter
      include ::Asciidoctor::Writer

      include ::Asciidoctor::Standoc::Base
      include ::Asciidoctor::Standoc::Front
      include ::Asciidoctor::Standoc::Lists
      include ::Asciidoctor::Standoc::Refs
      include ::Asciidoctor::Standoc::Inline
      include ::Asciidoctor::Standoc::Blocks
      include ::Asciidoctor::Standoc::Section
      include ::Asciidoctor::Standoc::Table
      include ::Asciidoctor::Standoc::Utils
      include ::Asciidoctor::Standoc::Cleanup
      include ::Asciidoctor::Standoc::Validate

      register_for "standoc"

      $xreftext = {}

      def initialize(backend, opts)
        super
        basebackend "html"
        outfilesuffix ".xml"
        @libdir = File.dirname(self.class::_file || __FILE__)

        install_fonts(opts)
      end

      class << self
        attr_accessor :_file
      end

      def self.inherited(k)
        k._file = caller_locations.first.absolute_path
      end

      # path to isodoc assets in child gems
      def html_doc_path(file)
        File.join(@libdir, "../../isodoc/html", file)
      end

      def flavor_name
        self.class.name.split("::")&.[](-2).downcase.to_sym
      end

      def fonts_manifest
        flavor = flavor_name
        registry = Metanorma::Registry.instance
        processor = registry.find_processor(flavor)

        if processor.nil?
          Metanorma::Util.log("[fontist] #{flavor} processor not found. " \
            "Please go to github.com/metanorma/metanorma/issues to report " \
            "this issue.", :warn)
          return nil
        elsif !defined? processor.fonts_manifest
          Metanorma::Util.log("[fontist] #{flavor} processor don't require " \
            "specific fonts", :debug)
          return nil
        end

        processor.fonts_manifest
      end

      def install_fonts(options={})
        if options[:no_install_fonts]
          Metanorma::Util.log("[fontist] Skip font installation because" \
            " --no-install-fonts argument passed", :debug)
          return
        end

        manifest = fonts_manifest
        return if manifest.nil?

        begin
          Fontist::Manifest::Install.from_hash(
            processor.fonts_manifest,
            confirmation: options[:agree_to_terms] ? "yes" : "no"
          )
        rescue Fontist::Errors::LicensingError
          if !options[:agree_to_terms]
            Metanorma::Util.log("[fontist] --agree-to-terms option missing." \
              " You must accept font licenses to install fonts.", :debug)
          elsif options[:continue_without_fonts]
            Metanorma::Util.log("[fontist] Processing will continue without" \
              " fonts installed", :debug)
          else
            Metanorma::Util.log("[fontist] Aborting without proper fonts" \
              " installed", :fatal)
          end
        rescue Fontist::Errors::NonSupportedFontError
          Metanorma::Util.log("[fontist] '#{font}' font is not supported. " \
            "Please go to github.com/metanorma/metanorma-#{flavor_name}/issues" \
            " to report this issue.", :info)
        end
      end

      alias_method :embedded, :content
      alias_method :verse, :quote
      alias_method :audio, :skip
      alias_method :video, :skip
      alias_method :inline_button, :skip
      alias_method :inline_kbd, :skip
      alias_method :inline_menu, :skip
    end
  end
end
