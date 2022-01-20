module Metanorma
  module Standoc
    class EmbedIncludeProcessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        return reader if reader.eof?

        lines = reader.read_lines
        while !lines.grep(/^embed::/).empty?
          headings = lines.grep(/^== /).map(&:strip)
          lines = lines.map do |line|
            /^embed::/.match?(line) ? embed(line, doc, reader, headings) : line
          end.flatten
        end
        reader.unshift_lines lines
        reader
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
        filter_sections(read(inc_path), headings)
      end

      def read(inc_path)
        ::File.open inc_path, "r" do |fd|
          if (first_line = fd.readline) && (first_line.start_with? "= ")
            while (line = fd.readline) && /^\S/.match?(line); end
            readlines_safe(fd)
          else
            [first_line] + readlines_safe(fd)
          end
        end
      end

      def filter_sections(lines, headings)
        skip = false
        lines.each_with_index.with_object([]) do |(l, i), m|
          if headings.include?(l.strip)
            skip = true
            m.unshift while !m.empty? && /^\S/.match?(m[-1])
          elsif skip && /^== /.match?(l)
            skip = false
            j = i and j -= 1 while j >= 0 && /^\S/.match?(m[j])
            lines[j..i].each { |n| m << n }
          else
            skip or m << l
          end
        end
      end
    end
  end
end
