module Metanorma
  module Standoc
    module Cleanup
      def textcleanup(result)
        text = result.flatten.map { |l| l.sub(/\s*$/, "") } * "\n"
        !@keepasciimath and text = asciimath2mathml(text)
        text = text.gsub(/\s+<fn /, "<fn ")
        text.gsub(%r{<passthrough\s+formats="metanorma">([^<]*)
                  </passthrough>}mx) { HTMLEntities.new.decode($1) }
      end

      IGNORE_DUMBQUOTES =
        "//pre | //pre//* | //tt | //tt//* | "\
        "//sourcecode | //sourcecode//* | //bibdata//* | //stem | "\
        "//stem//* | //figure[@class = 'pseudocode'] | "\
        "//figure[@class = 'pseudocode']//*".freeze

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
=begin
      def uninterrupt_quotes_around_xml(xmldoc)
        xmldoc.xpath("//*[following::text()[1]"\
                     "[starts-with(., '\"') or starts-with(., \"'\")]]")
          .each do |x|
          next if !x.ancestors("pre, tt, sourcecode, stem, figure").empty?

          uninterrupt_quotes_around_xml1(x)
        end
      end
=end
=begin
      def uninterrupt_quotes_around_xml(xmldoc)
        xmldoc.traverse do |n|
          next unless n.element? && n&.next&.text? &&
            n.ancestors("pre, tt, sourcecode, stem, figure").empty?
          next unless /^['"]/.match?(n.next.text)

          uninterrupt_quotes_around_xml1(n)
        end
      end
=end
      def uninterrupt_quotes_around_xml(xmldoc)
        xmldoc.traverse do |n|
          next unless n.text? && n&.previous&.element?
          next unless /^['"]/.match?(n.text)
          next unless n.previous.ancestors("pre, tt, sourcecode, stem, figure")
            .empty?

          uninterrupt_quotes_around_xml1(n.previous)
        end
      end

      def uninterrupt_quotes_around_xml1(elem)
        prev = elem.at(".//preceding::text()[1]") or return
        /\S$/.match?(prev.text) or return
        foll = elem.at(".//following::text()[1]")
        m = /^(["'][[:punct:]]*)(\s|$)/
          .match(HTMLEntities.new.decode(foll&.text)) or return
        foll.content = foll.text.sub(/^(["'][[:punct:]]*)/, "")
        prev.content = "#{prev.text}#{m[1]}"
      end

      def dumb2smart_quotes(xmldoc)
        (xmldoc.xpath("//*[child::text()]") - xmldoc.xpath(IGNORE_DUMBQUOTES))
          .each do |x|
          x.children.each do |n|
            next unless n.text?

            /[-'"(<>]|\.\.|\dx/.match(n) or next

            n.replace(Metanorma::Utils::smartformat(n.text))
          end
        end
      end

      def dumbquote_cleanup(xmldoc)
        xmldoc.traverse do |n|
          next unless n.text?

          n.replace(n.text.gsub(/(?<=\p{Alnum})\u2019(?=\p{Alpha})/, "'")) # .
        end
      end
    end
  end
end
