module Metanorma
  module Standoc
    class EmbedIncludeProcessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        return reader if reader.eof?

        lines = reader.readlines
        headings = lines.grep(/^== /).map(&:strip)
        ret = lines.each_with_object({ lines: [], hdr: [] }) do |line, m|
          process1(line, m, doc, reader, headings)
        end
        doc.attributes["embed_hdr"] = ret[:hdr]
        ::Asciidoctor::Reader.new ret[:lines].flatten
      end

      def process1(line, acc, doc, reader, headings)
        if /^embed::/.match?(line)
          e = embed(line, doc, reader, headings)
          acc[:lines] << e[:lines]
          acc[:hdr] << e[:hdr]
        else
          acc[:lines] << line
        end
        acc
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

      def read(inc_path)
        ::File.open inc_path, "r" do |fd|
          readlines_safe(fd).map(&:chomp)
        end
      end

      def embed(line, doc, reader, headings)
        inc_path = filename(line, doc, reader) or return line
        lines = filter_sections(read(inc_path), headings)
        doc = Asciidoctor::Document.new [], { safe: :safe }
        reader = ::Asciidoctor::PreprocessorReader.new doc, lines
        ret = strip_header(reader.read_lines)
        embed_recurse(ret, doc, reader, headings)
      end

      def embed_recurse(ret, doc, reader, headings)
        ret1 = ret[:lines].each_with_object({ lines: [], hdr: [] }) do |line, m|
          process1(line, m, doc, reader, headings)
        end
        { lines: ret1[:lines],
          hdr: { text: ret[:hdr].join("\n"), child: ret1[:hdr] } }
      end

      def strip_header(lines)
        return { lines: lines, hdr: nil } unless !lines.empty? &&
          lines.first.start_with?("= ")

        skip = true
        lines.each_with_object({ hdr: [], lines: [] }) do |l, m|
          m[skip ? :hdr : :lines] << l
          skip = false if !/\S/.match?(l)
        end
      end

      def filter_sections(lines, headings)
        skip = false
        lines.each_with_index.with_object([]) do |(l, i), m|
          if headings.include?(l.strip)
            skip = true
            m.pop while !m.empty? && /^\S/.match?(m[-1])
          elsif skip && /^== |^embed::|^include::/.match?(l)
            skip = false
            j = i
            j -= 1 while j >= 0 && /^\S/.match?(m[j])
            lines[j..i].each { |n| m << n }
          else skip or m << l
          end
        end
      end
    end
  end
end
