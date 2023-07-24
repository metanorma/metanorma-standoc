require "uuidtools"
require "yaml"
require "csv"
require_relative "./macros_inline"
require_relative "./macros_plantuml"
require_relative "./macros_terms"
require_relative "./macros_form"
require_relative "./macros_note"
require_relative "./macros_embed"
require_relative "./datamodel/attributes_table_preprocessor"
require_relative "./datamodel/diagram_preprocessor"
require "metanorma-plugin-datastruct"
require "metanorma-plugin-glossarist"
require "metanorma-plugin-lutaml"

module Metanorma
  module Standoc
    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(line)
        /^(?<prefix>[ \t]*)(?<suffix>.*)$/ =~ line
        prefix = prefix.gsub(/\t/, "\u00a0\u00a0\u00a0\u00a0")
          .gsub(/ /, "\u00a0")
        prefix + suffix
      end

      def supply_br(lines)
        ignore = false
        lines.each_with_index do |l, i|
          /^(--+|====+|\|===|\.\.\.\.+|\*\*\*\*+|\+\+\+\++|````+|____\+)$/
            .match(l) && (ignore = !ignore)
          next if l.empty? || l.match(/ \+$/) || /^\[.*\]$/.match?(l) || ignore
          next if i == lines.size - 1 ||
            (i < lines.size - 1 && lines[i + 1].empty?)

          lines[i] += " +"
        end
        lines
      end

      def process(parent, reader, attrs)
        attrs["role"] = "pseudocode"
        lines = reader.lines.map { |m| init_indent(m) }
        create_block(parent, :example, supply_br(lines),
                     attrs, content_model: :compound)
      end
    end

    class NamedEscapePreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(_document, reader)
        c = HTMLEntities.new
        lines = reader.readlines.map do |l|
          l.split(/(&[A-Za-z][^;]*;)/).map do |s|
            /^&[A-Za-z]/.match?(s) ? c.encode(c.decode(s), :hexadecimal) : s
          end.join
        end
        ::Asciidoctor::Reader.new lines
      end
    end
  end
end
