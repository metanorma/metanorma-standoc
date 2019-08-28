require "asciidoctor"
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
require "asciidoctor/standoc/i18n"
require "asciidoctor/standoc/reqt"
require_relative "./macros.rb"

module Asciidoctor
  module Standoc
    # A {Converter} implementation that generates Standoc output, and a document
    # schema encapsulation of the document for validation
    class Converter
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
      include ::Asciidoctor::Standoc::I18n
      include ::Asciidoctor::Standoc::Cleanup
      include ::Asciidoctor::Standoc::Validate

      register_for "standoc"

      $xreftext = {}

      def initialize(backend, opts)
        super
        basebackend "html"
        outfilesuffix ".xml"
        @libdir = File.dirname(__FILE__)
      end

      # path to isodoc assets in child gems
      def html_doc_path(file)
        File.join(@libdir, File.join("../../isodoc/html", file))
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
