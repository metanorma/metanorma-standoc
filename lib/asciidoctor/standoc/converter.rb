require "asciidoctor"
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
require_relative "./macros"

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
        inline_macro Asciidoctor::Standoc::IndexXrefInlineMacro
        inline_macro Asciidoctor::Standoc::IndexRangeInlineMacro
        inline_macro Asciidoctor::Standoc::AddMacro
        inline_macro Asciidoctor::Standoc::DelMacro
        inline_macro Asciidoctor::Standoc::FormInputMacro
        inline_macro Asciidoctor::Standoc::FormLabelMacro
        inline_macro Asciidoctor::Standoc::FormTextareaMacro
        inline_macro Asciidoctor::Standoc::FormSelectMacro
        inline_macro Asciidoctor::Standoc::FormOptionMacro
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
      end

      class << self
        attr_accessor :_file
      end

      def self.inherited(konv) # rubocop:disable Lint/MissingSuper
        konv._file = caller_locations(1..1).first.absolute_path
      end

      # path to isodoc assets in child gems
      def html_doc_path(file)
        File.join(@libdir, "../../isodoc/html", file)
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
