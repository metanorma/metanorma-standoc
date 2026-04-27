require "uuidtools"
require "yaml"
require "csv"
require_relative "macros_inline"
require_relative "macros_terms"
require_relative "macros_form"
require_relative "macros_note"
require_relative "macros_embed"
require_relative "macros_link"
require_relative "macros_nosub"
require_relative "macros_number"
require "metanorma-plugin-glossarist"
require "metanorma-plugin-lutaml"
require "metanorma-plugin-plantuml"

module Metanorma
  module Standoc
    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(line)
        /^(?<prefix>[ \t]*)(?![ \t])(?<suffix>.*)$/ =~ line
        prefix = prefix.gsub("\t", "\u00a0\u00a0\u00a0\u00a0")
          .tr(" ", "\u00a0")
        prefix + suffix
      end

      def supply_br(lines)
        ignore = false
        lines.each_with_index do |l, i|
          /^(--+|====+|\|===|\.\.\.\.+|\*\*\*\*+|\+\+\+\++|````+|____\+)$/
            .match(l) and (ignore = !ignore)
          next if l.empty? || l.match(/ \+$/) || /^\[.*\]$/.match?(l) ||
            ignore || i == lines.size - 1 ||
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
      def process(document, reader)
        c = HTMLEntities.new
        p = Metanorma::Utils::LineStatus.new
        lines = reader.lines.map do |l|
          p.process(l)
          p.pass ? l : convert(l, c)
        end
        log(document, lines)
        ::Asciidoctor::PreprocessorReader.new document, lines
      end

      def convert(line, esc)
        line.split(/(&[A-Za-z][^&;]*;)/).map do |s|
          /^&[A-Za-z]/.match?(s) ? esc.encode(esc.decode(s), :hexadecimal) : s
        end.join
      end

      # debugging output of results of all preprocessing,
      # including include files concatenation and Lutaml/Liquid processing
      def log(doc, text)
        source = doc.attr("docfile") || "metanorma"
        dirname  = File.dirname(source)
        basename = File.basename(source, ".*")
        fname = File.join(dirname, "#{basename}.asciidoc.log.txt")
        File.open(fname, "w:UTF-8") do |f|
          f.write(text.join("\n"))
        end
      end
    end

    class ColumnBreakBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
      use_dsl
      named :columnbreak

      def process(parent, _reader, _attrs)
        create_pass_block parent, "<columnbreak/>", {}, subs: nil
      end
    end
  end
end
