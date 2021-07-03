# frozen_string_literal: true.

module Asciidoctor
  module Standoc
    # Intelligent term lookup xml modifier
    class TermLookupCleanup
      AUTOMATIC_GENERATED_ID_REGEXP = /\A_/.freeze
      EXISTING_TERM_REGEXP = /\Aterm-/.freeze

      attr_reader :xmldoc, :termlookup, :log

      def initialize(xmldoc, log)
        @xmldoc = xmldoc
        @log = log
        @termlookup = {}
        @idhash = {}
      end

      def call
        @idhash = populate_idhash
        @termlookup = replace_automatic_generated_ids_terms
        set_termxref_tags_target
      end

      private

      def populate_idhash
        xmldoc.xpath("//*[@id]").each_with_object({}) do |n, mem|
          next unless /^term-/.match?(n["id"])

          mem[n["id"]] = true
        end
      end

      def set_termxref_tags_target
        xmldoc.xpath("//termxref").each do |node|
          target = normalize_ref_id(node.text)
          if termlookup[target].nil?
            remove_missing_ref(node, target)
            next
          end
          x = node.at("../displayterm")
          modify_ref_node(x, target)
          node.name = "refterm"
        end
      end

      def remove_missing_ref(node, target)
        log.add("AsciiDoc Input", node,
                %(Error: Term reference in `term[#{target}]` missing: \
                "#{target}" is not defined in document))
        node.name = "strong"
        display = node&.at("../displayterm")&.remove&.children
        display = [] if display.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "term <tt>#{node.text}</tt>#{d} "\
          "not resolved via ID <tt>#{target}</tt>"
      end

      def modify_ref_node(node, target)
        node.name = "xref"
        node["target"] = termlookup[target]
      end

      def replace_automatic_generated_ids_terms
        xmldoc.xpath("//term").each.with_object({}) do |term_node, res|
          normalize_id_and_memorize(term_node, res, "./preferred")
        end
      end

      def normalize_id_and_memorize(term_node, res_table, text_selector)
        term_text = normalize_ref_id(term_node.at(text_selector).text)
        unless AUTOMATIC_GENERATED_ID_REGEXP.match(term_node["id"]).nil?
          id = unique_text_id(term_text)
          term_node["id"] = id
          @idhash[id] = true
        end
        res_table[term_text] = term_node["id"]
      end

      def normalize_ref_id(text)
        text.downcase.gsub(/[[:space:]]/, "-")
      end

      def unique_text_id(text)
        unless @idhash["term-#{text}"]
          return "term-#{text}"
        end

        (1..Float::INFINITY).lazy.each do |index|
          unless @idhash["term-#{text}-#{index}"]
            break("term-#{text}-#{index}")
          end
        end
      end
    end
  end
end
