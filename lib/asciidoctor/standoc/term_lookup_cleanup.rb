# frozen_string_literal: true.

module Asciidoctor
  module Standoc
    # Intelligent term lookup xml modifier
    class TermLookupCleanup
      AUTOMATIC_GENERATED_ID_REGEXP = /\A_/.freeze
      EXISTING_TERM_REGEXP = /\Aterm-/.freeze
      EXISTING_SYMBOL_REGEXP = /\Asymbol-/.freeze

      attr_reader :xmldoc, :termlookup, :log

      def initialize(xmldoc, log)
        @xmldoc = xmldoc
        @log = log
        @termlookup = { term: {}, symbol: {} }
        @idhash = {}
      end

      def call
        @idhash = populate_idhash
        @termlookup = replace_automatic_generated_ids_terms
        set_termxref_tags_target
        concept_cleanup
      end

      private

      def concept_cleanup
        xmldoc.xpath("//concept").each do |n|
          n.delete("type")
        end
      end

      def populate_idhash
        xmldoc.xpath("//*[@id]").each_with_object({}) do |n, mem|
          next unless /^(term|symbol)-/.match?(n["id"])

          mem[n["id"]] = true
        end
      end

      def set_termxref_tags_target
        xmldoc.xpath("//termxref").each do |node|
          target = normalize_ref_id(node.text)
          if termlookup[:term][target].nil? && termlookup[:symbol][target].nil?
            remove_missing_ref(node, target)
            next
          end
          x = node.at("../xrefrender")
          modify_ref_node(x, target)
          node.name = "refterm"
        end
      end

      def remove_missing_ref(node, target)
        if node.at("../concept[@type = 'symbol']")
          remove_missing_ref_symbol(node, target)
        else
          remove_missing_ref_term(node, target)
        end
      end

      def remove_missing_ref_term(node, target)
        log.add("AsciiDoc Input", node,
                %(Error: Term reference in `term[#{target}]` missing: \
                "#{target}" is not defined in document))
        node.name = "strong"
        node.at("../xrefrender").remove
        display = node&.at("../renderterm")&.remove&.children
        display = [] if display.nil? || display&.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "term <tt>#{node.text}</tt>#{d} "\
          "not resolved via ID <tt>#{target}</tt>"
      end

      def remove_missing_ref_symbol(node, target)
        log.add("AsciiDoc Input", node,
                %(Error: Symbol reference in `symbol[#{target}]` missing: \
                "#{target}" is not defined in document))
        node.name = "strong"
        node.at("../xrefrender").remove
        display = node&.at("../renderterm")&.remove&.children
        display = [] if display.nil? || display&.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "symbol <tt>#{node.text}</tt>#{d} "\
          "not resolved via ID <tt>#{target}</tt>"
      end

      def modify_ref_node(node, target)
        node.name = "xref"
        s = termlookup[:symbol][target]
        t = termlookup[:term][target]
        type = node.parent["type"]
        if type == "term" || !type && t
          node["target"] = t
        elsif type == "symbol" || !type && s
          node["target"] = s
        end
      end

      def replace_automatic_generated_ids_terms
        r = xmldoc.xpath("//term").each.with_object({}) do |n, res|
          normalize_id_and_memorize(n, res, "./preferred", "term")
        end
        s = xmldoc.xpath("//definitions//dt").each.with_object({}) do |n, res|
          normalize_id_and_memorize(n, res, ".", "symbol")
        end
        { term: r, symbol: s }
      end

      def normalize_id_and_memorize(node, res_table, text_selector, prefix)
        term_text = normalize_ref_id(node.at(text_selector).text)
        unless AUTOMATIC_GENERATED_ID_REGEXP.match(node["id"]).nil? &&
            !node["id"].nil?
          id = unique_text_id(term_text, prefix)
          node["id"] = id
          @idhash[id] = true
        end
        res_table[term_text] = node["id"]
      end

      def normalize_ref_id(text)
        text.downcase.gsub(/[[:space:]]/, "-")
      end

      def unique_text_id(text, prefix)
        unless @idhash["#{prefix}-#{text}"]
          return "#{prefix}-#{text}"
        end

        (1..Float::INFINITY).lazy.each do |index|
          unless @idhash["#{prefix}-#{text}-#{index}"]
            break("#{prefix}-#{text}-#{index}")
          end
        end
      end
    end
  end
end
