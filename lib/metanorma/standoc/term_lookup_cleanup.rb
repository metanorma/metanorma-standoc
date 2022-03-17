# frozen_string_literal: true.
require "metanorma/standoc/utils"

module Metanorma
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
        @termlookup = { term: {}, symbol: {}, secondary2primary: {} }
        @idhash = {}
      end

      def call
        @idhash = populate_idhash
        @termlookup = replace_automatic_generated_ids_terms
        set_termxref_tags_target
        concept_cleanup
        related_cleanup
      end

      private

      def concept_cleanup
        xmldoc.xpath("//concept").each do |n|
          n.delete("type")
          refterm = n.at("./refterm") or next
          p = @termlookup[:secondary2primary][refterm.text] and
            refterm.children = p
        end
      end

      def related_cleanup
        xmldoc.xpath("//related").each do |n|
          refterm = n.at("./refterm") or next
          p = @termlookup[:secondary2primary][refterm.text] and
            refterm.children = p
          refterm.replace("<preferred><expression><name>#{refterm.children.to_xml}"\
                          "</name></expression></preferred>")
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
          target = normalize_ref_id(node)
          if termlookup[:term][target].nil? && termlookup[:symbol][target].nil?
            remove_missing_ref(node, target)
            next
          end
          x = node.at("../xrefrender") and modify_ref_node(x, target)
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
                %(Error: Term reference to `#{target}` missing: \
                "#{target}" is not defined in document))
        node.name = "strong"
        node&.at("../xrefrender")&.remove
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
        node&.at("../xrefrender")&.remove
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
        if type == "term" || ((!type || node.parent.name == "related") && t)
          node["target"] = t
        elsif type == "symbol" ||
            ((!type || node.parent.name == "related") && s)
          node["target"] = s
        end
      end

      def replace_automatic_generated_ids_terms
        r = xmldoc.xpath("//term").each.with_object({}) do |n, res|
          normalize_id_and_memorize(n, res, "./preferred//name", "term")
          normalize_id_and_memorize(n, res, "./admitted//name", "term")
        end
        s = xmldoc.xpath("//definitions//dt").each.with_object({}) do |n, res|
          normalize_id_and_memorize(n, res, ".", "symbol")
        end
        { term: r, symbol: s, secondary2primary: pref_secondary2primary }
      end

      def pref_secondary2primary
        term = ""
        xmldoc.xpath("//term").each.with_object({}) do |n, res|
          n.xpath("./preferred//name").each_with_index do |p, i|
            i.zero? and term = p.text
            i.positive? and res[p.text] = term
          end
          n.xpath("./admitted//name").each { |p| res[p.text] = term }
        end
      end

      def normalize_id_and_memorize(node, res_table, text_selector, prefix)
        normalize_id_and_memorize_init(node, res_table, text_selector, prefix)
        memorize_other_pref_terms(node, res_table, text_selector)
      end

      def normalize_id_and_memorize_init(node, res_table, text_selector, prefix)
        term_text = normalize_ref_id(node.at(text_selector)) or return
        unless AUTOMATIC_GENERATED_ID_REGEXP.match(node["id"]).nil? &&
            !node["id"].nil?
          id = unique_text_id(term_text, prefix)
          node["id"] = id
          @idhash[id] = true
        end
        res_table[term_text] = node["id"]
      end

      def memorize_other_pref_terms(node, res_table, text_selector)
        node.xpath(text_selector).each_with_index do |p, i|
          next unless i.positive?

          res_table[normalize_ref_id(p)] = node["id"]
        end
      end

      def normalize_ref_id(term)
        return nil if term.nil?

        t = term.dup
        t.xpath(".//index").map(&:remove)
        Metanorma::Utils::to_ncname(t.text.strip.downcase
          .gsub(/[[:space:]]+/, "-"))
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
