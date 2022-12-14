module Metanorma
  module Standoc
    module Cleanup
      def textcleanup(result)
        text = result.flatten.map { |l| l.sub(/\s*\Z/, "") } * "\n"
        !@keepasciimath and text = asciimath2mathml(text)
        text = text.gsub(/\s+<fn /, "<fn ")
        %w(passthrough passthrough-inline).each do |v|
          text.gsub!(%r{<#{v}\s+formats="metanorma">([^<]*)
                    </#{v}>}mx) { @c.decode($1) }
        end
        text
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

      IGNORE_QUOTES_ELEMENTS =
        %w(pre tt sourcecode stem asciimath figure bibdata passthrough
           identifier).freeze

      def uninterrupt_quotes_around_xml_skip(elem)
        !(/\A['"]/.match?(elem.text) &&
          elem.previous.path.gsub(/\[\d+\]/, "").split(%r{/})[1..-2]
          .intersection(IGNORE_QUOTES_ELEMENTS).empty? &&
          ((elem.previous.text.strip.empty? &&
            !empty_tag_with_text_content?(elem.previous)) ||
           ignoretext?(elem.previous)))
      end

      def uninterrupt_quotes_around_xml1(elem)
        prev = elem.at(".//preceding::text()[1]") or return
        /\S\Z/.match?(prev.text) or return
        foll = elem.at(".//following::text()[1]")
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
           newcontent floating-title tab).include? elem.name
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

          ancestors = x.path.gsub(/\[\d+\]/, "").split(%r{/})[1..-2]
          ancestors.intersection(IGNORE_QUOTES_ELEMENTS).empty? or next
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
