require "pathname"

module Asciidoctor
  class PreprocessorNoIfdefsReader < PreprocessorReader
    private

    def preprocess_conditional_directive(_keyword, _target, _delimiter, _text)
      false # decline to resolve idefs
    end

    def resolve_include_path(expanded_target, attrlist, parsed_attrs)
      inc_path, target_type, relpath = super
      if inc_path && !%i(file uri).include?(target_type)
        # include has been skipped because of error
        n = peek_line(true)
        /^Unresolved directive in/.match?(n) and
          @document.converter.log
            &.add("Include", nil,
                  HTMLEntities.new.encode(n, :basic), severity: 0)
      end
      [inc_path, target_type, relpath]
    end
  end
end

module Metanorma
  module Standoc
    # resolve all includes before doing any further preprocessing
    class ResolveIncludePreprocessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        r = ::Asciidoctor::PreprocessorNoIfdefsReader.new doc, reader.lines
        ::Asciidoctor::PreprocessorNoIfdefsReader.new doc, r.readlines
      end
    end

    class EmbedIncludeProcessor < Asciidoctor::Extensions::Preprocessor
      def process(doc, reader)
        reader.eof? and return reader
        r = ::Asciidoctor::PreprocessorNoIfdefsReader.new doc, reader.lines
        p = Metanorma::Utils::LineStatus.new
        lines = r.readlines
        headings = lines.grep(/^== /).map(&:strip)
        ret = lines.each_with_object(embed_acc(doc, r)) do |line, m|
          process_line(line, m, headings, p)
        end
        return_to_document(doc, ret)
      end

      def embed_acc(doc, reader)
        { lines: [], hdr: [], id: [],
          orig: doc, doc:, file: nil, path: nil,
          reader:, prev: nil }
      end

      # presupposes single embed
      def return_to_document(doc, embed)
        doc.attributes["embed_hdr"] = embed[:hdr]
        doc.attributes["embed_id"] = embed[:id]
        read_flattened_embeds(flatten_embeds(embed), doc)
      end

      # lines can contain recursive embed structs, containing the lines to read
      # and the file they are in; read these into the (new) reader.
      # This is intended to resolve any file crossreferences, with
      # file paths resolved relative to current file directory
      # -- but it won't: https://github.com/metanorma/metanorma-standoc/issues/802
      def read_flattened_embeds(ret, doc)
        reader = ::Asciidoctor::PreprocessorReader.new doc
        b = Pathname.new doc.base_dir
        ret.reverse.each do |l|
          # if l[:file]
          # new = Pathname.new(l[:path]).relative_path_from(b).to_s
          # reader.push_include l[:lines], new, l[:path]
          reader.unshift_lines l[:lines]
          # else reader.unshift_lines l[:lines]
          # end
        end
        reader
      end

      # lines can contain recursive embed structs, which are resolved into a
      # flat listing of included line chunks (top level doc has { file: nil } )
      def flatten_embeds(emb)
        acc = []
        ret = emb[:lines].each_with_object([]) do |l, m|
          if l.is_a?(Hash)
            acc, m = update_embeds(acc, m, emb)
            flatten_embeds(l).each { |x| m << x }
          else acc << l end
        end
        acc, ret = update_embeds(acc, ret, emb)
        ret
      end

      def update_embeds(lines, acc, emb)
        lines.empty? or
          acc << { file: emb[:file], path: emb[:path], lines: }
        [[], acc]
      end

      def process_line(line, acc, headings, status)
        status.process(line)
        if !status.pass && /^embed::/.match?(line)
          e = embed(line, acc, headings, status)
          acc = process_embed(acc, e, acc[:prev])
        else
          acc[:lines] << line
        end
        acc[:prev] = line
        acc
      end

      def process_embed(acc, embed, prev)
        acc, embed = process_embed_anchor(acc, embed, prev)
        acc[:lines] << embed
        acc[:hdr] << embed[:hdr]
        acc[:id] += embed[:id]
        acc
      end

      def process_embed_anchor(acc, embed, prev)
        if /^\[\[.+\]\]/.match?(prev) # anchor
          acc[:id] << prev.sub(/^\[\[/, "").sub(/\]\]$/, "")
          i = embed[:lines].index { |x| /^== /.match?(x) } and
            embed[:lines][i] += " #{prev}" # => bookmark
        end
        [acc, embed]
      end

      def filename(line, acc)
        m = /^embed::([^\[]+)\[/.match(line)
        f = acc[:doc].normalize_system_path m[1], acc[:reader].dir, nil,
                                            target_name: "include file"
        unless File.exist?(f)
          err = "Missing embed file: #{line}"
          raise err
        end
        [m[1], f]
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

      def embed(line, acc, headings, status)
        fname, inc_path = filename(line, acc)
        lines = filter_sections(read(inc_path), headings)
        n = Asciidoctor::Document
          .new [], { safe: :safe, base_dir: File.dirname(inc_path) }
        r = ::Asciidoctor::PreprocessorNoIfdefsReader.new n, lines
        ret = embed_acc(n, r).merge(strip_header(r.readlines))
          .merge(file: fname, path: inc_path, orig: acc[:orig])
        ret[:hdr] or
          raise "Embedding an incomplete document with no header: #{ret[:path]}"
        embed_recurse(ret, n, r, headings, status)
      end

      def embed_recurse(ret, doc, reader, headings, status)
        ret1 = ret[:lines].each_with_object(embed_acc(doc, reader)) do |line, m|
          process_line(line, m, headings, status)
        end
        ret.merge(
          { lines: ret1[:lines], id: ret[:id] + ret1[:id],
            hdr: { text: ret[:hdr].join("\n"), child: ret1[:hdr] } },
        )
      end

      def strip_header(lines)
        return { lines:, hdr: nil } unless !lines.empty? &&
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
