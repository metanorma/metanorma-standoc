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
        inline_macro Asciidoctor::Standoc::AltTermInlineMacro
        inline_macro Asciidoctor::Standoc::DeprecatedTermInlineMacro
        inline_macro Asciidoctor::Standoc::DomainTermInlineMacro
        inline_macro Asciidoctor::Standoc::InheritInlineMacro
        inline_macro Asciidoctor::Standoc::HTML5RubyMacro
        inline_macro Asciidoctor::Standoc::ConceptInlineMacro
        inline_macro Asciidoctor::Standoc::AutonumberInlineMacro
        inline_macro Asciidoctor::Standoc::VariantInlineMacro
        block Asciidoctor::Standoc::ToDoAdmonitionBlock
        treeprocessor Asciidoctor::Standoc::ToDoInlineAdmonitionBlock
        block Asciidoctor::Standoc::PlantUMLBlockMacro
        block Asciidoctor::Standoc::PseudocodeBlockMacro
      end

      include ::Asciidoctor::Converter
      include ::Asciidoctor::Writer

      include ::Asciidoctor::Standoc::Base
      include ::Asciidoctor::Standoc::Front
      include ::Asciidoctor::Standoc::Lists
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

      def fonts_manifest
        File.join(@libdir, "fonts_manifest.yaml")
      end

      def install_fonts(options={})
        if options[:no_install_fonts] || fonts_manifest.nil? || !File.exist?(fonts_manifest)
          Metanorma::Util.log("[fontinst] Skip font installation process", :debug)
          return
        end

        begin
          Fontist::Manifest::Install.call(
            fonts_manifest,
            confirmation: options[:confirm_license] ? "yes" : "no"
          )
        rescue Fontist::Errors::LicensingError
          log_type = options[:continue_without_fonts] ? :error : :fatal
          Metanorma::Util.log("[fontinst] Error: License acceptance required to install a necessary font." \
            "Accept required licenses with: `metanorma setup --agree-to-terms`.", log_type)

        rescue Fontist::Errors::NonSupportedFontError
          Metanorma::Util.log("[fontinst] The font `#{font}` is not yet supported.", :info)
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
