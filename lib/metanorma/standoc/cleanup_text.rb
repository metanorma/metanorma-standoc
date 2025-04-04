module Metanorma
  module Standoc
    module Cleanup
      def textcleanup(result)
        text = result.flatten.map(&:rstrip) * "\n"
        text = text.gsub(/(?<!\s)\s+<fn /, "<fn ")
        %w(passthrough passthrough-inline).each do |v|
          text.gsub!(%r{<#{v}\s+formats="metanorma">([^<]*)
                    </#{v}>}mx) { @c.decode($1) }
        end
        text
      end

      def ancestor_include?(elem, ancestors)
        path = elem.path.gsub(/\[\d+\]/, "").split(%r{/})[1..-2]
        !path.intersection(ancestors).empty?
      end

      # process example/p, example/sourcecode, not example on its own:
      # this is about stripping lines for blocks containing inline elems & text
      def linebreak_cleanup(xmldoc)
        xmldoc.xpath(STRIP_LINEBREAK_ELEMENTS.map { |e| "//#{e}" }.join(" | "))
          .each do |b|
            b.xpath(STRIP_LINEBREAK_ELEMENTS.map { |e| ".//#{e}" }.join(" | "))
              .empty? or next
            linebreak_cleanup_block(gather_text_for_linebreak_cleanup(b))
          end
      end

      def linebreak_cleanup_block(block)
        block.each_with_index do |e, i|
          e[:skip] and next
          lines = lines_strip_textspan(e, block[i + 1])
          out = Metanorma::Utils.line_sanitise(lines)
          e[:last] or out.pop
          e[:elem].replace(out.join)
        end
      end

      def lines_strip_textspan(span, nextspan)
        lines = span[:text].lines[0..-2].map(&:rstrip) <<
          span[:text].lines[-1]&.sub(/\n$/, "")
        # no final line rstrip: can be space linking to next line
        span[:last] or lines << nextspan[:text].lines.first # next token context
        lines
      end

      def gather_text_for_linebreak_cleanup(block)
        x = block.xpath(".//text()").map do |e|
          { elem: e, text: e.text,
            skip: ancestor_include?(e, PRESERVE_LINEBREAK_ELEMENTS) }
        end
        x.empty? and return x
        x.each { |e| e[:skip] ||= !e[:text].include?("\n") }
        x[-1][:last] = true
        x
      end

      def smartquotes_cleanup(xmldoc)
        xmldoc.xpath("//date").each { |d| Metanorma::Utils::endash_date(d) }
        if @smartquotes then smartquotes_cleanup1(xmldoc)
        else dumbquote_cleanup(xmldoc)
        end
      end

      def smartquotes_cleanup1(xmldoc)
        uninterrupt_quotes_around_xml(xmldoc)
        dumb2smart_quotes(xmldoc)
      end

      # "abc<tag/>", def => "abc",<tag/> def
      def uninterrupt_quotes_around_xml(xmldoc)
        xmldoc.traverse do |n|
          next unless n.text? && n&.previous&.element?
          next if uninterrupt_quotes_around_xml_skip(n)

          uninterrupt_quotes_around_xml1(n.previous)
        end
      end

      # "abc<tag/>", def => "abc",<tag/> def
      # TODO?
      def uninterrupt_quotes_around_xml1(xmldoc)
        xmldoc.xpath("//text()[preceding-sibling::*[1]]").each do |n|
          uninterrupt_quotes_around_xml_skip(n) and next
          uninterrupt_quotes_around_xml1(n.previous)
        end
      end

      IGNORE_QUOTES_ELEMENTS =
        %w(pre tt sourcecode stem asciimath figure bibdata passthrough
           identifier metanorma-extension).freeze

      PRESERVE_LINEBREAK_ELEMENTS =
        %w(pre sourcecode passthrough metanorma-extension).freeze

      STRIP_LINEBREAK_ELEMENTS =
        %w(title name variant-title figure example review admonition
           note li th td dt dd p quote label annotation
           preferred admitted related deprecates field-of-application
           usage-info expression pronunciation grammar-value domain
           definition termnote termexample modification description
           newcontent floating-title).freeze

      def uninterrupt_quotes_around_xml_skip(elem)
        !(/\A['"]/.match?(elem.text) &&
        !ancestor_include?(elem.previous, IGNORE_QUOTES_ELEMENTS) &&
          ((elem.previous.text.strip.empty? &&
            !empty_tag_with_text_content?(elem.previous)) ||
           ignoretext?(elem.previous)))
      end

      def uninterrupt_quotes_around_xml1(elem)
        prev = elem.at(".//preceding::text()[1]") or return
        /\S\Z/.match?(prev.text) or return
        foll = elem.at(".//following::text()[1]")
        /"$/.match?(prev.text) and /^"/.match?(foll&.text) and return # "<tag/>"
        m = /\A(["'][[:punct:]]*)(\s|\Z)/
          .match(@c.decode(foll&.text)) or return
        foll.content = foll.text.sub(/\A(["'][[:punct:]]*)/, "")
        prev.content = "#{prev.text}#{m[1]}"
      end

      IGNORE_TEXT_ELEMENTS =
        %w(index fn).freeze

      def ignoretext?(elem)
        IGNORE_TEXT_ELEMENTS.include? elem.name
      end

      def block?(elem)
        %w(title name variant-title clause figure annex example introduction
           foreword acknowledgements note li th td dt dd p quote label
           abstract preferred admitted related deprecates field-of-application
           usage-info expression pronunciation grammar-value domain
           definition termnote termexample modification description
           newcontent floating-title tab review admonition annotation).include? elem.name
      end

      def empty_tag_with_text_content?(elem)
        %w(eref xref termref link).include? elem.name
      end

      def dumb2smart_quotes(xmldoc)
        prev = ""
        xmldoc.traverse do |x|
          block?(x) and prev = ""
          empty_tag_with_text_content?(x) and prev = "dummy"
          x.text? or next

          # ancestors = x.path.gsub(/\[\d+\]/, "").split(%r{/})[1..-2]
          # ancestors.intersection(IGNORE_QUOTES_ELEMENTS).empty? or next
          ancestor_include?(x, IGNORE_QUOTES_ELEMENTS) and next
          dumb2smart_quotes1(x, prev)
          prev = x.text
        end
      end

      def dumb2smart_quotesx(xmldoc)
        # TODO?>
        prev = ""
        xmldoc.xpath("//* | //text()").each do |x|
          x.is_a?(Nokogiri::XML::Node) or next
          block?(x) and prev = ""
          empty_tag_with_text_content?(x) and prev = "dummy"
          x.text? or next
          ancestor_include?(x, IGNORE_QUOTES_ELEMENTS) and next
          dumb2smart_quotes1(x, prev)
          prev = x.text
        end
      end

      def dumb2smart_quotes1(curr, prev)
        /[-'"(<>]|\.\.|\dx/.match?(curr.text) or return

        /\A["']/.match?(curr.text) && prev.match?(/\S\Z/) and
          curr.content = curr.text.sub(/\A"/, "”").sub(/\A'/, "‘")
        curr.replace(Metanorma::Utils::smartformat(curr.text))
      end

      def dumbquote_cleanup(xmldoc)
        xmldoc.traverse do |n|
          next unless n.text? && /\u2019/.match?(n.text)

          n.replace(@c.encode(
                      @c.decode(n.text)
            .gsub(/(?<=\p{Alnum})\u2019(?=\p{Alpha})/, "'"),
                      :basic, :hexadecimal
                    ))
        end
      end
    end
  end
end
