require "metanorma/standoc/utils"
require_relative "validate_image"
require_relative "validate_section"
require_relative "validate_table"
require_relative "validate_term"
require_relative "validate_schema"
require "nokogiri"
require "iev"

module Metanorma
  module Standoc
    module Validate
      def content_validate(doc)
        @doctype = doc.at("//bibdata/ext/doctype")&.text
        repeat_id_validate(doc.root) # feeds xref_validate, termsect_validate
        xref_validate(doc) # feeds nested_asset_validate
        section_validate(doc)
        norm_ref_validate(doc)
        iev_validate(doc.root)
        concept_validate(doc, "concept", "refterm")
        concept_validate(doc, "related", "preferred//name")
        preferred_validate(doc)
        termsect_validate(doc)
        table_validate(doc)
        requirement_validate(doc)
        image_validate(doc)
        block_validate(doc)
        math_validate(doc)
        fatalerrors = @log.abort_messages
        fatalerrors.empty? or
          clean_abort("\n\nFATAL ERRORS:\n\n#{fatalerrors.join("\n\n")}", doc)
      end

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def math_validate(doc)
        doc.xpath("//m:math", "m" => MATHML_NS).each do |m|
          if m.parent["validate"] == "false"
            m.parent.delete("validate")
          else
            math = mathml_sanitise(m.dup)
            Plurimath::Math.parse(math, "mathml").to_mathml
          end
        rescue StandardError => e
          math_validate_error(math, m, e)
        end
      end

      def mathml_sanitise(math)
        math.to_xml(encoding: "US-ASCII").gsub(/ xmlns=["'][^"']+["']/, "")
          .gsub(%r{<[^:/>]+:}, "<").gsub(%r{</[^:/>]+:}, "</")
      end

      def math_validate_error(math, elem, error)
        a = elem.parent.at("./asciimath")
        l = elem.parent.at("./latexmath")
        orig = ""
        a and orig += "\n\tAsciimath original: #{@c.decode(a.children.to_xml)}"
        l and orig += "\n\tLatexmath original: #{@c.decode(l.children.to_xml)}"
        @log.add("STANDOC_33", elem, params: [math, error, orig])
      end

      def nested_asset_validate(doc)
        nested_asset_validate_basic(doc)
        nested_note_validate(doc)
      end

      def nested_asset_validate_basic(doc)
        a = "//example | //figure | //termnote | //termexample | //table"
        doc.xpath("#{a} | //note").each do |m|
          m.xpath(a.gsub(%r{//}, ".//")).each do |n|
            nested_asset_report(m, n, doc)
          end
        end
      end

      def nested_note_validate(doc)
        doc.xpath("//termnote | //note").each do |m|
          m.xpath(".//note").each do |n|
            nested_asset_report(m, n, doc)
          end
        end
      end

      def nested_asset_report(outer, inner, doc)
        outer.name == "figure" && inner.name == "figure" and return
        @log.add("STANDOC_34", inner, params: [inner.name, outer.name])
        nested_asset_xref_report(outer, inner, doc)
      end

      def nested_asset_xref_report(outer, inner, _doc)
        i = @doc_xrefs[inner["anchor"]] or return
        @log.add("STANDOC_35", i, params: [inner.name, outer.name, i.to_xml])
      end

      def validate(doc)
        @log.add_error_ranges(doc)
        content_validate(doc)
        schema_validate(formattedstr_strip(doc.dup), schema_location)
      end

      # Check should never happen with content ids, but will check it anyway
      # since consequences are so catastrophic
      def repeat_id_validate1(elem)
        if @doc_ids[elem["id"]]
          @log.add("STANDOC_36", elem, params: [elem['id'], @doc_ids[elem['id']][:line]])
        else
          @doc_ids[elem["id"]] =
            { line: elem.line, anchor: elem["anchor"] }.compact
        end
      end

      def repeat_anchor_validate1(elem)
        if @doc_anchors[elem["anchor"]]
          @log.add("STANDOC_36", elem, params: [elem['anchor'], @doc_anchors[elem['anchor']][:line]])
        else
          @doc_anchors[elem["anchor"]] = { line: elem.line, id: elem["id"] }
          @doc_anchor_seq << elem["anchor"]
        end
      end

      # Check should never happen with content ids, but will check it anyway
      def repeat_id_validate(doc)
        repeat_id_validate_prep
        doc.xpath("//*[@id]").each do |x|
          @doc_id_seq << x["id"]
          repeat_id_validate1(x)
          x["anchor"] and repeat_anchor_validate1(x)
        end
        @doc_id_seq_hash = @doc_id_seq.each_with_index
          .with_object({}) do |(x, i), m|
          m[x] = i
        end
        @doc_anchor_seq_hash = @doc_anchor_seq.each_with_index
          .with_object({}) do |(x, i), m|
          m[x] = i
        end
      end

      def repeat_id_validate_prep
        @doc_ids = {} # hash of all ids in document to line number, anchor
        @doc_anchors = {} # hash of all anchors in document to line number, id
        @doc_id_seq = [] # ordered list of all ids in document
        @doc_anchor_seq = [] # ordered list of all anchors in document
      end

      # Retrieve anchors between two nominated values
      # (exclusive of start_id AND exclusive of end_id)
      def get_anchors_between(start_id, end_id)
        start_index = @doc_anchor_seq_hash[start_id]
        end_index = @doc_anchor_seq_hash[end_id]
        start_index.nil? || end_index.nil? and return []
        start_index >= end_index and return []
        @doc_anchor_seq[start_index...end_index]
      end

      # manually check for xref/@target et sim. integrity
      def xref_validate(doc)
        xref_validate_exists(doc)
        xref_range_record(doc)
      end

      def xref_validate_exists(doc)
        @doc_xrefs = {}
        Metanorma::Utils::anchor_attributes.each do |a|
          doc.xpath("//#{a[0]}/@#{a[1]}").each do |x|
            @doc_xrefs[x.text] = x.parent
            @doc_anchors[x.text] and next
            @log.add("STANDOC_38", x.parent, params: [x.text])
          end
        end
      end

      # If there is an xref range, record the IDs between the two targets
      def xref_range_record(doc)
        doc.xpath("//xref//location[@connective = 'to']").each do |to|
          process_range_location(to)
        end
      end

      def process_range_location(to_location)
        # Get the preceding location element if it exists
        from = to_location.previous_element
        from && from.name == "location" or return
        from["target"] && to_location["target"] or return
        get_anchors_between(from["target"], to_location["target"])
          .each { |id| @doc_xrefs[id] = from }
      end

      def block_validate(doc)
        nested_asset_validate(doc)
        all_empty_block_validate(doc)
      end

      def all_empty_block_validate(doc)
        %w(note example admonition figure quote pre).each do |tag|
          empty_block_validate(doc, "//#{tag}", nil)
        end
        empty_block_validate(doc, "//sourcecode", "body")
        empty_block_validate(doc, "//formula", "stem")
        empty_block_validate(doc, "//ol", "li")
        empty_block_validate(doc, "//ul", "li")
        empty_block_validate(doc, "//dl", "dt")
      end

      def empty_block_validate(doc, tag, body)
        # require "debug"; binding.b
        doc.xpath(tag).each do |t|
          body and t = t.at("./#{body}")
          empty_block?(t) or next
          @log.add("STANDOC_39", t, params: [tag.sub(/^\/\//, '')])
        end
      end

      def empty_block?(block)
        block.nil? and return
        content = block.children.reject { |n| n.name == "name" }
        content.map do |n|
          %w(image xref eref).include?(n.name) ? n.name : n
        end
        content.map(&:to_s).join.strip.empty?
      end
    end
  end
end
