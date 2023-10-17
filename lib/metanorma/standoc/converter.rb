require "asciidoctor"
require_relative "version"
require_relative "base"
require_relative "front"
require_relative "lists"
require_relative "ref"
require_relative "inline"
require_relative "blocks"
require_relative "section"
require_relative "table"
require_relative "validate"
require_relative "utils"
require_relative "cleanup"
require_relative "reqt"
require_relative "macros"

module Metanorma
  module Standoc
    # A {Converter} implementation that generates Standoc output, and a document
    # schema encapsulation of the document for validation
    class Converter
      Asciidoctor::Extensions.register do
        preprocessor Metanorma::Standoc::EmbedIncludeProcessor
        preprocessor Metanorma::Standoc::NamedEscapePreprocessor
        preprocessor Metanorma::Standoc::LinkProtectPreprocessor
        preprocessor Metanorma::Standoc::Datamodel::AttributesTablePreprocessor
        preprocessor Metanorma::Standoc::Datamodel::DiagramPreprocessor
        preprocessor Metanorma::Plugin::Datastruct::Json2TextPreprocessor
        preprocessor Metanorma::Plugin::Datastruct::Yaml2TextPreprocessor
        preprocessor Metanorma::Plugin::Glossarist::DatasetPreprocessor
        inline_macro Metanorma::Standoc::PreferredTermInlineMacro
        inline_macro Metanorma::Standoc::DateInlineMacro
        inline_macro Metanorma::Standoc::SpanInlineMacro
        inline_macro Metanorma::Standoc::AltTermInlineMacro
        inline_macro Metanorma::Standoc::AdmittedTermInlineMacro
        inline_macro Metanorma::Standoc::DeprecatedTermInlineMacro
        inline_macro Metanorma::Standoc::RelatedTermInlineMacro
        inline_macro Metanorma::Standoc::DomainTermInlineMacro
        inline_macro Metanorma::Standoc::InheritInlineMacro
        inline_macro Metanorma::Standoc::HTML5RubyMacro
        inline_macro Metanorma::Standoc::IdentifierInlineMacro
        inline_macro Metanorma::Standoc::ConceptInlineMacro
        inline_macro Metanorma::Standoc::AutonumberInlineMacro
        inline_macro Metanorma::Standoc::VariantInlineMacro
        inline_macro Metanorma::Standoc::FootnoteBlockInlineMacro
        inline_macro Metanorma::Standoc::TermRefInlineMacro
        inline_macro Metanorma::Standoc::SymbolRefInlineMacro
        inline_macro Metanorma::Standoc::IndexXrefInlineMacro
        inline_macro Metanorma::Standoc::IndexRangeInlineMacro
        inline_macro Metanorma::Standoc::AddMacro
        inline_macro Metanorma::Standoc::DelMacro
        inline_macro Metanorma::Standoc::FormInputMacro
        inline_macro Metanorma::Standoc::FormLabelMacro
        inline_macro Metanorma::Standoc::FormTextareaMacro
        inline_macro Metanorma::Standoc::FormSelectMacro
        inline_macro Metanorma::Standoc::FormOptionMacro
        inline_macro Metanorma::Standoc::ToCInlineMacro
        inline_macro Metanorma::Standoc::PassInlineMacro
        inline_macro Metanorma::Standoc::StdLinkInlineMacro
        block Metanorma::Standoc::ToDoAdmonitionBlock
        block Metanorma::Standoc::EditorAdmonitionBlock
        treeprocessor Metanorma::Standoc::EditorInlineAdmonitionBlock
        treeprocessor Metanorma::Standoc::ToDoInlineAdmonitionBlock
        block Metanorma::Standoc::PlantUMLBlockMacro
        block Metanorma::Standoc::PseudocodeBlockMacro
        block_macro Metanorma::Standoc::ColumnBreakBlockMacro
      end

      include ::Asciidoctor::Converter
      include ::Asciidoctor::Writer

      include ::Metanorma::Standoc::Base
      include ::Metanorma::Standoc::Front
      include ::Metanorma::Standoc::Lists
      include ::Metanorma::Standoc::Refs
      include ::Metanorma::Standoc::Inline
      include ::Metanorma::Standoc::Blocks
      include ::Metanorma::Standoc::Section
      include ::Metanorma::Standoc::Table
      include ::Metanorma::Standoc::Utils
      include ::Metanorma::Standoc::Cleanup
      include ::Metanorma::Standoc::Validate

      register_for "standoc"

      $xreftext = {}

      def initialize(backend, opts)
        super
        basebackend "html"
        outfilesuffix ".xml"
        @libdir = File.dirname(self.class::_file || __FILE__)
        @c = HTMLEntities.new
      end

      class << self
        attr_accessor :_file, :embed_hdr
      end

      def self.inherited(konv) # rubocop:disable Lint/MissingSuper
        konv._file = caller_locations(1..1).first.absolute_path
      end

      # path to isodoc assets in child gems
      def html_doc_path(file)
        File.join(@libdir, "../../isodoc/html", file)
      end

      def content(node)
        node.content
      end

      def skip(node, name = nil)
        name = name || node.node_name
        w = "converter missing for #{name} node in Metanorma backend"
        @log.add("AsciiDoc Input", node, w)
        nil
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
