require "htmlentities"
require "uri"
require "mime/types"
require "base64"

module Asciidoctor
  module Standoc
    module Blocks
      def id_attr(node = nil)
        { id: Utils::anchor_or_uuid(node) }
      end

      def id_unnum_attr(node)
        attr_code( id: Utils::anchor_or_uuid(node),
                  unnumbered: node.option?("unnumbered") ? "true" : nil,
                  subsequence: node.attr("subsequence") )
      end

      def formula_attr(node)
        attr_code( id: Utils::anchor_or_uuid(node),
                  inequality: node.option?("inequality") ? "true" : nil,
                  unnumbered: node.option?("unnumbered") ? "true" : nil,
                  subsequence: node.attr("subsequence") )
      end

      # open block is a container of multiple blocks,
      # treated as a single block.
      # We append each contained block to its parent
      def open(node)
        role = node.role || node.attr("style")
        Utils::reqt_subpart(role) and
          return requirement_subpart(node)
        result = []
        node.blocks.each do |b|
          result << send(b.context, b)
        end
        result
      end

      def literal(node)
        noko do |xml|
          xml.figure **id_attr(node) do |f|
            figure_title(node, f)
            f.pre node.lines.join("\n"), **{ id: Utils::anchor_or_uuid }
          end
        end
      end

      # NOTE: html escaping is performed by Nokogiri
      def stem(node)
        stem_content = node.lines.join("\n")
        noko do |xml|
          xml.formula **formula_attr(node) do |s|
            stem_parse(stem_content, s, node.style.to_sym)
          end
        end
      end

      def sidebar_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless /T/.match date
        { reviewer: node.attr("reviewer") || node.attr("source") || "(Unknown)",
          id: Utils::anchor_or_uuid(node),
          date: date,
          from: node.attr("from"),
          to: node.attr("to") || node.attr("from") }
      end

      def sidebar(node)
        return unless draft?
        noko do |xml|
          xml.review **attr_code(sidebar_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def todo_attrs(node)
        date = node.attr("date") || Date.today.iso8601.gsub(/\+.*$/, "")
        date += "T00:00:00Z" unless /T/.match date
        { reviewer: node.attr("reviewer") || node.attr("source") || "(Unknown)",
          id: Utils::anchor_or_uuid(node),
          date: date }
      end

      def todo(node)
        noko do |xml|
          xml.review **attr_code(todo_attrs(node)) do |r|
            wrap_in_para(node, r)
          end
        end
      end

      def termnote(n)
        noko do |xml|
          xml.termnote **id_attr(n) do |ex|
            wrap_in_para(n, ex)
          end
        end.join("\n")
      end

      def note(n)
        a = noko do |xml|
          xml.note **id_attr(n) do |c|
            wrap_in_para(n, c)
          end
        end
        noko do |xml|
          xml.note **id_attr(n) do |c|
            wrap_in_para(n, c)
          end
        end.join("\n")
      end

      def admonition_attrs(node)
        name = node.attr("name")
        if type = node.attr("type")
          ["danger", "safety precautions"].each do |t|
            name = t if type.casecmp(t).zero?
          end
        end
        { id: Utils::anchor_or_uuid(node), type: name }
      end

      def admonition(node)
        return termnote(node) if in_terms?
        return note(node) if node.attr("name") == "note"
        return todo(node) if node.attr("name") == "todo"
        noko do |xml|
          xml.admonition **admonition_attrs(node) do |a|
            node.title.nil? or a.name { |name| name << node.title }
            wrap_in_para(node, a)
          end
        end.join("\n")
      end

      def term_example(node)
        noko do |xml|
          xml.termexample **id_attr(node) do |ex|
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def example(node)
        return term_example(node) if in_terms?
        role = node.role || node.attr("style")
        %w(recommendation requirement permission).include?(role) and
          return requirement(node, role)
        return pseudocode_example(node) if role == "pseudocode"
        example_proper(node)
      end

      def pseudocode_example(node)
        noko do |xml|
          xml.figure **{id: Asciidoctor::Standoc::Utils::anchor_or_uuid(node),
                        class: "pseudocode"} do |ex|
            figure_title(node, ex)
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def example_proper(node)
        noko do |xml|
          xml.example **id_unnum_attr(node) do |ex|
            node.title.nil? or ex.name { |name| name << node.title }
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end

      def preamble(node)
        noko do |xml|
          xml.foreword do |xml_abstract|
            xml_abstract.title { |t| t << (node.blocks[0].title || "Foreword") }
            content = node.content
            xml_abstract << content
          end
        end.join("\n")
      end

      def datauri(uri)
        return uri if /^data:/.match(uri)
        types = MIME::Types.type_for(@localdir + uri)
        type = types ? types.first.to_s : 'text/plain; charset="utf-8"'
        bin = File.open(@localdir + uri, 'rb') {|io| io.read}
        data = Base64.strict_encode64(bin)
        "data:#{type};base64,#{data}"
      end

      def image_attributes(node)
        uri = node.image_uri (node.attr("target") || node.target)
        types = /^data:/.match(uri) ? datauri2mime(uri) : MIME::Types.type_for(uri)
        type = types.first.to_s
        uri = uri.sub(%r{^data:image/\*;}, "data:#{type};")
        { src: @datauriimage ? datauri(uri) : uri,
          id: Utils::anchor_or_uuid,
          mimetype: type,
          height: node.attr("height") || "auto",
          width: node.attr("width") || "auto" ,
          filename: node.attr("filename"),
          title: node.attr("titleattr"),
          alt: node.alt == node.attr("default-alt") ? nil : node.alt }
      end

      def figure_title(node, f)
        return if node.title.nil?
        f.name { |name| name << node.title }
      end

      def image(node)
        noko do |xml|
          xml.figure **id_unnum_attr(node) do |f|
            figure_title(node, f)
            f.image **attr_code(image_attributes(node))
          end
        end
      end

      def inline_image(node)
        noko do |xml|
          xml.image **attr_code(image_attributes(node))
        end.join("")
      end

      def paragraph(node)
        return termsource(node) if node.role == "source"
        attrs = { align: node.attr("align"),
                  id: Utils::anchor_or_uuid(node) }
        noko do |xml|
          xml.p **attr_code(attrs) do |xml_t|
            xml_t << node.content
          end
        end.join("\n")
      end

      def quote_attrs(node)
        { id: Utils::anchor_or_uuid(node), align: node.attr("align") }
      end

      def quote_attribution(node, out)
        if node.attr("citetitle")
          m = /^(?<cite>[^,]+)(,(?<text>.*$))?$/m.match node.attr("citetitle")
          out.source m[:text],
            **attr_code(target: m[:cite], type: "inline")
        end
        if node.attr("attribution")
          out.author { |a| a << node.attr("attribution") }
        end
      end

      def quote(node)
        noko do |xml|
          xml.quote **attr_code(quote_attrs(node)) do |q|
            quote_attribution(node, q)
            wrap_in_para(node, q)
          end
        end
      end

      def listing_attrs(node)
        { lang: node.attr("language"),
          id: Utils::anchor_or_uuid(node),
          filename: node.attr("filename") }
      end

      # NOTE: html escaping is performed by Nokogiri
      def listing(node)
        fragment = ::Nokogiri::XML::Builder.new do |xml|
          xml.sourcecode **attr_code(listing_attrs(node)) do |s|
            figure_title(node, s)
            s << node.content
          end
        end
        fragment.to_xml(encoding: "US-ASCII", save_with:
                        Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      end

      def pass(node)
        node.content
      end
    end
  end
end
