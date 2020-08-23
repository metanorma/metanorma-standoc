require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "uuidtools"
require "sterile"
require "mimemagic"

module Asciidoctor
  module Standoc
    module Utils
      class << self
        def anchor_or_uuid(node = nil)
          uuid = UUIDTools::UUID.random_create
          node.nil? || node.id.nil? || node.id.empty? ? "_" + uuid : node.id
        end

        def asciidoc_sub(x)
          return nil if x.nil?
          return "" if x.empty?
          d = Asciidoctor::Document.new(x.lines.entries, { header_footer: false,
                                                           backend: :standoc })
          b = d.parse.blocks.first
          b.apply_subs(b.source)
        end

        def localdir(node)
          docfile = node.attr("docfile")
          docfile.nil? ? './' : Pathname.new(docfile).parent.to_s + '/'
        end

        def smartformat(n)
          n.gsub(/ --? /, "&#8201;&#8212;&#8201;").
            gsub(/--/, "&#8212;").smart_format.gsub(/</, "&lt;").gsub(/>/, "&gt;")
        end

        def endash_date(elem)
          elem.traverse do |n|
            n.text? and n.replace(n.text.gsub(/\s+--?\s+/, "&#8211;").gsub(/--/, "&#8211;"))
          end
        end

        # Set hash value using keys path
        # mod from https://stackoverflow.com/a/42425884
        def set_nested_value(hash, keys, new_val)
          key = keys[0]
          if keys.length == 1
            hash[key] = hash[key].is_a?(Array) ?  (hash[key] << new_val) :
              hash[key].nil? ?  new_val : [hash[key], new_val]
            return hash
          end
          if hash[key].is_a?(Array)
            hash[key][-1] = {} if hash[key][-1].nil?
            set_nested_value(hash[key][-1], keys[1..-1], new_val)
          elsif hash[key].nil? || hash[key].empty?
            hash[key] = {}
            set_nested_value(hash[key], keys[1..-1], new_val)
          elsif hash[key].is_a?(Hash) && !hash[key][keys[1]]
            set_nested_value(hash[key], keys[1..-1], new_val)
          elsif !hash[key][keys[1]]
            hash[key] = [hash[key], {}]
            set_nested_value(hash[key][-1], keys[1..-1], new_val)
          else
            set_nested_value(hash[key], keys[1..-1], new_val)
          end
        end

        def flatten_rawtext_lines(node, result)
          node.lines.each do |x|
            if node.respond_to?(:context) && (node.context == :literal ||
                node.context == :listing)
              result << x.gsub(/</, "&lt;").gsub(/>/, "&gt;")
            else
              # strip not only HTML <tag>, and Asciidoc xrefs <<xref>>
              result << x.gsub(/<[^>]*>+/, "")
            end
          end
          result
        end

        # if node contains blocks, flatten them into a single line;
        # and extract only raw text
        def flatten_rawtext(node)
          result = []
          if node.respond_to?(:blocks) && node.blocks?
            node.blocks.each { |b| result << flatten_rawtext(b) }
          elsif node.respond_to?(:lines)
            result = flatten_rawtext_lines(node, result)
          elsif node.respond_to?(:text)
            result << node.text.gsub(/<[^>]*>+/, "")
          else
            result << node.content.gsub(/<[^>]*>+/, "")
          end
          result.reject(&:empty?)
        end

        def reqt_subpart(x)
          %w(specification measurement-target verification import label
             subject inherit classification title).include? x
        end
      end

      def convert(node, transform = nil, opts = {})
        transform ||= node.node_name
        opts.empty? ? (send transform, node) : (send transform, node, opts)
      end

      def document_ns_attributes(_doc)
        nil
      end

      NOKOHEAD = <<~HERE.freeze
          <!DOCTYPE html SYSTEM
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
          <html xmlns="http://www.w3.org/1999/xhtml">
          <head> <title></title> <meta charset="UTF-8" /> </head>
          <body> </body> </html>
      HERE

      # block for processing XML document fragments as XHTML,
      # to allow for HTMLentities
      # Unescape special chars used in Asciidoctor substitution processing
      def noko(&block)
        doc = ::Nokogiri::XML.parse(NOKOHEAD)
        fragment = doc.fragment("")
        ::Nokogiri::XML::Builder.with fragment, &block
        fragment.to_xml(encoding: "US-ASCII", indent: 0).lines.map do |l|
          l.gsub(/>\n$/, ">").gsub(/\s*\n$/m, " ").gsub("&#150;", "\u0096").
            gsub("&#151;", "\u0097").gsub("&#x96;", "\u0096").
            gsub("&#x97;", "\u0097")
        end
      end

      def attr_code(attributes)
        attributes = attributes.reject { |_, val| val.nil? }.map
        attributes.map do |k, v|
          [k, (v.is_a? String) ? HTMLEntities.new.decode(v) : v]
        end.to_h
      end

      # if the contents of node are blocks, output them to out;
      # else, wrap them in <p>
      def wrap_in_para(node, out)
        if node.blocks? then out << node.content
        else
          out.p { |p| p << node.content }
        end
      end

      def datauri2mime(uri)
        %r{^data:image/(?<imgtype>[^;]+);base64,(?<imgdata>.+)$} =~ uri
        type = nil
        imgtype = "png" unless /^[a-z0-9]+$/.match imgtype
        Tempfile.open(["imageuri", ".#{imgtype}"]) do |file|
          type = datauri2mime1(file, imgdata)
        end
        [type]
      end

      def datauri2mime1(file, imgdata)
        type = nil
        begin
          file.binmode
          file.write(Base64.strict_decode64(imgdata))
          file.rewind
          type = MimeMagic.by_magic(file)
        ensure
          file.close!
        end
        type
      end

      SUBCLAUSE_XPATH = "//clause[not(parent::sections)]"\
        "[not(ancestor::boilerplate)]".freeze

       def isodoc(lang, script, i18nyaml = nil)
        conv = html_converter(EmptyAttr.new)
        i18n = conv.i18n_init(lang, script, i18nyaml)
        conv.metadata_init(lang, script, i18n)
        conv
      end

       class EmptyAttr
        def attr(_x)
          nil
        end
        def attributes
          {}
        end
      end
    end
  end
end
