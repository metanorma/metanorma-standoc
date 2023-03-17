module Metanorma
  module Standoc
    class EmbedIncludeProcessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        reader.eof? and return reader
        lines = reader.readlines
        headings = lines.grep(/^== /).map(&:strip)
        ret = lines.each_with_object(embed_acc(doc, reader)) do |line, m|
          process_line(line, m, headings)
        end
        return_to_document(doc, ret)
      end

      def embed_acc(doc, reader)
        { lines: [], hdr: [], id: [],
          doc: doc, reader: reader, prev: nil }
      end

      # presupposes single embed
      def return_to_document(doc, ret)
        doc.attributes["embed_hdr"] = ret[:hdr]
        doc.attributes["embed_id"] = ret[:id]
        ::Asciidoctor::Reader.new ret[:lines].flatten
      end

      def process_line(line, acc, headings)
        if /^embed::/.match?(line)
          e = embed(line, acc[:doc], acc[:reader], headings)
          acc = process_embed(acc, e, acc[:prev])
        else
          acc[:lines] << line
        end
        acc[:prev] = line
        acc
      end

      def process_embed(acc, embed, prev)
        if /^\[\[.+\]\]/.match?(prev) # anchor
          acc[:id] << prev.sub(/^\[\[/, "").sub(/\]\]$/, "")
          i = embed[:lines].index { |x| /^== /.match?(x) } and
            embed[:lines][i] += " #{prev}" # => bookmark
        end
        acc[:lines] << embed[:lines]
        acc[:hdr] << embed[:hdr]
        acc[:id] += embed[:id]
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
        ret = embed_acc(doc, reader).merge(strip_header(reader.read_lines))
        embed_recurse(ret, doc, reader, headings)
      end

      def embed_recurse(ret, doc, reader, headings)
        ret1 = ret[:lines].each_with_object(embed_acc(doc, reader)) do |line, m|
          process_line(line, m, headings)
        end
        { lines: ret1[:lines], id: ret[:id] + ret1[:id],
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
