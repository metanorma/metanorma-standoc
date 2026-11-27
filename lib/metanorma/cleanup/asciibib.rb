require "relaton/bib"
require "relaton/bib/hash_parser_v1"

module Metanorma
  module Standoc
    module Asciibib
      def ref_dl_cleanup(xmldoc)
        xmldoc.xpath("//clause[@bibitem = 'true']").each do |c|
          bib = dl_bib_extract(c) or next
          normalize_asciibib_contact(bib, c)
          validate_ref_dl(bib, c)
          xml = Relaton::Bib::ItemData.new(
            **Relaton::Bib::HashParserV1.hash_to_bib(bib),
          ).to_xml or next
          bibitem = Nokogiri::XML(xml)
          ref_dl_cleanup_id(bibitem.root, c, bib["id"])
          wrap_asciibib_contact(bibitem.root)
          default_asciibib_role(bibitem.root, c)
          c.replace(bibitem.root)
        end
      end

      # metanorma-standoc#1412: the citation target is the authored
      # id::, but the legacy Relaton hash parser strips non-word
      # characters from the id (ANSI.X9.95 becomes ANSIX995), leaving
      # cross-references dangling. The anchor is set from the authored
      # string instead.
      def ref_dl_cleanup_id(bibitem, clause, authored_id = nil)
        bibitem["anchor"] = bibitem["id"]
        # the authored id:: is the citation target and wins over the
        # clause's derived heading anchor: AsciiBib includes pull a
        # foreign draft's bibitems in, and their heading ids must not
        # shadow the authored ids the citations name (metanorma-
        # standoc#1412 follow-up)
        if authored_id && !authored_id.empty?
          bibitem["anchor"] = authored_id
        elsif clause["anchor"] && !/^_/.match?(clause["anchor"])
          bibitem["anchor"] = clause["anchor"]
        end
        add_id(bibitem)
      end

      LEGACY_ASCIIDIB_CONTACT_KEYS =
        %w(street city state country postcode).freeze

      # metanorma-standoc#1413: the legacy AsciiBib syntax puts street/
      # city/state/country/postcode directly under contact; the
      # canonical form nests them under contact.address, which is what
      # the Relaton hash parser reads. Accept the legacy keys with a
      # deprecation warning naming the canonical form.
      def normalize_asciibib_contact(bib, clause)
        contributors = bib["contributor"]
        contributors = [contributors] unless contributors.is_a?(Array)
        contributors.each do |c|
          org = c.is_a?(Hash) && c["organization"]
          next unless org.is_a?(Hash)
          contacts = org["contact"]
          next unless contacts.is_a?(Hash)

          legacy = contacts.slice(*LEGACY_ASCIIDIB_CONTACT_KEYS)
          next if legacy.empty?

          @log.add("STANDOC_73", clause, params: [legacy.keys.join(", ")])
          contacts["address"] = contacts["address"] ? contacts["address"].merge(legacy) : legacy
          LEGACY_ASCIIDIB_CONTACT_KEYS.each { |k| contacts.delete(k) }
        end
      end

      # metanorma-standoc#1413: the Relaton exporter emits address/
      # phone/email/uri directly under organization; the Metanorma
      # schema nests them in a contact element.
      def wrap_asciibib_contact(bibitem)
        bibitem.xpath(".//organization").each do |org|
          direct = org.xpath("./address | ./phone | ./email | ./uri")
          next if direct.empty?

          contact = Nokogiri::XML::Node.new("contact", org.document)
          logo = org.at_xpath("./logo")
          logo&.before(contact) || org << contact
          direct.each { |n| contact << n }
        end
      end

      # metanorma-standoc#1413: the schema requires a role on every
      # contributor; a role-less AsciiBib contributor renders as
      # author (the released 1.15.3 behaviour) with a warning naming
      # the explicit key.
      def default_asciibib_role(org, clause)
        org.xpath("./contributor").each do |c|
          next if c.at("./role")

          @log.add("STANDOC_74", clause, params: [])
          role = Nokogiri::XML::Node.new("role", org.document)
          role["type"] = "author"
          c.before(role)
        end
      end

      # do not accept implicit id
      def validate_ref_dl(bib, clause)
        id = bib["id"]
        id ||= clause["anchor"] unless /^_/.match?(clause["anchor"])
        unless id
          @log.add("STANDOC_10", clause, params: [clause.to_xml])
          return
        end
        @refids << id
        validate_ref_dl1(bib, id, clause)
      end

      def validate_ref_dl1(bib, id, clause)
        if !bib["title"]
          @log.add("STANDOC_11", clause, params: [id])
        end
        if !bib["docid"]
          @log.add("STANDOC_12", clause, params: [id])
        end
      end

      def extract_from_p(tag, bib, key)
        return unless bib[tag]

        "<#{key}>#{bib[tag].at('p').children}</#{key}>"
      end

      # if the content is a single paragraph, replace it with its children
      # single links replaced with uri
      def p_unwrap(para)
        elems = para.elements
        if elems.size == 1 && elems[0].name == "p"
          link_unwrap(elems[0]).children.to_xml.strip
        else
          para.to_xml.strip
        end
      end

      def dd_bib_extract(dtd)
        dtd.children.empty? and return nil
        dtd.at("./dl") and return dl_bib_extract(dtd)
        elems = dtd.remove.elements
        return p_unwrap(dtd) unless elems.size == 1 &&
          %w(ol ul).include?(elems[0].name)

        elems[0].xpath("./li").each_with_object([]) do |li, ret|
          ret << p_unwrap(li)
        end
      end

      def add_to_hash(bib, key, val)
        Metanorma::Utils::set_nested_value(bib, key.split("."), val)
      end

      # definition list, with at most one level of unordered lists
      def dl_bib_extract(clause, nested: false)
        dl = clause.at("./dl") or return
        key = ""
        bib = dl.xpath("./dt | ./dd").each_with_object({}) do |dtd, m|
          (dtd.name == "dt" and key = dtd.text.sub(/:+$/, "")) and next
          add_to_hash(m, key, dd_bib_extract(dtd))
        end
        clause.xpath("./clause").each do |c1|
          key = c1.at("./title")&.text&.downcase&.strip
          %w(contributor relation series).include?(key) or next
          add_to_hash(bib, key, dl_bib_extract(c1, nested: true))
        end
        dl_bib_extract_title(bib, clause, nested)
      end

      def dl_bib_extract_title(bib, clause, nested)
        (!nested && clause.at("./title")) or return bib
        title = clause.at("./title").remove.children.to_xml
        bib["title"] = [bib["title"]] if bib["title"].is_a?(Hash) ||
          bib["title"].is_a?(String)
        bib["title"] ||= []
        title.empty? or bib["title"] << { "content" => title, "type" => "main",
                                          "language" => @lang }
        bib
      end
    end
  end
end
