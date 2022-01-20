module Metanorma
  module Standoc
    class EmbedIncludeProcessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        return reader if reader.eof?

        lines = reader.readlines.to_enum
        while !lines.grep(/^embed::/).empty?
          headings = lines.grep(/^== /).map(&:strip)
          lines = lines.map do |line|
            /^embed::/.match?(line) ? embed(line, doc, reader, headings) : line
          end.flatten
        end
        ::Asciidoctor::Reader.new lines
      end

      def filename(line, doc, reader)
        m = /^embed::([^\[]+)\[/.match(line)
        f = doc.normalize_system_path m[1], reader.dir, nil,
                                      target_name: "include file"
        File.exist?(f) ? f : nil
      end

      def readlines_safe(file)
        if file.eof? then []
        else file.readlines
        end
      end

      def embed(line, doc, reader, headings)
        inc_path = filename(line, doc, reader) or return line
        lines = filter_sections(read(inc_path), headings)
        doc = Asciidoctor::Document.new [], { safe: :safe }
        reader = ::Asciidoctor::PreprocessorReader.new doc, lines
        strip_header(reader.read_lines)
      end

      def read(inc_path)
        ::File.open inc_path, "r" do |fd|
          readlines_safe(fd).map(&:chomp)
        end
      end

      def strip_header(lines)
        return lines unless !lines.empty? && lines.first.start_with?("= ")

        skip = true
        lines.each_with_object([]) do |l, m|
          m << l unless skip
          skip = false if !/\S/.match?(l)
        end
      end

      def filter_sections(lines, headings)
        skip = false
        lines.each_with_index.with_object([]) do |(l, i), m|
          if headings.include?(l.strip)
            skip = true
            m.unshift while !m.empty? && /^\S/.match?(m[-1])
          elsif skip && /^== |^embed::|^include::/.match?(l)
            skip = false
            j = i
            j -= 1 while j >= 0 && /^\S/.match?(m[j])
            lines[j..i].each { |n| m << n }
          else
            skip or m << l
          end
        end
      end
    end
  end
end
