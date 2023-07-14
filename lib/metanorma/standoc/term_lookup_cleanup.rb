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
        @c = HTMLEntities.new
        @terms_tags = xmldoc.xpath("//terms").each_with_object({}) do |t, m|
          m[t["id"]] = true
        end
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
          p = @termlookup[:secondary2primary][@c.encode(refterm.text)] and
            refterm.children = p
        end
      end

      def related_cleanup
        xmldoc.xpath("//related").each do |n|
          refterm = n.at("./refterm") or next
          p = @termlookup[:secondary2primary][@c.encode(refterm.text)] and
            refterm.children = p
          refterm.replace("<preferred><expression>" \
                          "<name>#{refterm.children.to_xml}" \
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
          target = normalize_ref_id1(node)
          if termlookup[:term][target].nil? && termlookup[:symbol][target].nil?
            remove_missing_ref(node, target)
            next
          end
          x = node.at("../xrefrender") and modify_ref_node(x, target)
          node.name = "refterm"
        end
      end

      def remove_missing_ref(node, target)
        if node.at("./parent::concept[@type = 'symbol']")
          log.add("AsciiDoc Input", node,
                  remove_missing_ref_msg(node, target, :symbol))
          remove_missing_ref_symbol(node, target)
        else
          log.add("AsciiDoc Input", node,
                  remove_missing_ref_msg(node, target, :term))
          remove_missing_ref_term(node, target)
        end
      end

      def remove_missing_ref_msg(node, target, type)
        type == :symbol and return <<~LOG
          Error: Symbol reference in `symbol[#{target}]` missing: "#{target}" is not defined in document
        LOG
        ret = <<~LOG
          Error: Term reference to `#{target}` missing: "#{target}" is not defined in document
        LOG
        remove_missing_ref_msg1(node, target, ret)
      end

      def remove_missing_ref_msg1(_node, target, ret)
        target2 = "_#{target.downcase.gsub(/-/, '_')}"
        if @terms_tags[target] || @terms_tags[target2]
          ret.strip!
          ret += ". Did you mean to point to a subterm?"
        end
        ret
      end

      def remove_missing_ref_term(node, target)
        node.name = "strong"
        node.at("../xrefrender")&.remove
        display = node.at("../renderterm")&.remove&.children
        display = [] if display.nil? || display.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "term <tt>#{@c.encode(node.text)}</tt>#{d} " \
                        "not resolved via ID <tt>#{target}</tt>"
      end

      def remove_missing_ref_symbol(node, target)
        node.name = "strong"
        node.at("../xrefrender")&.remove
        display = node.at("../renderterm")&.remove&.children
        display = [] if display.nil? || display.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "symbol <tt>#{@c.encode(node.text)}</tt>#{d} " \
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
          norm_id_memorize(n, res, "./preferred//name", "term", true)
          norm_id_memorize(n, res, "./admitted//name", "term", true)
        end
        s = xmldoc.xpath("//definitions//dt").each.with_object({}) do |n, res|
          norm_id_memorize(n, res, ".", "symbol", false)
        end
        { term: r, symbol: s, secondary2primary: pref_secondary2primary }
      end

      def pref_secondary2primary
        term = ""
        xmldoc.xpath("//term").each.with_object({}) do |n, res|
          n.xpath("./preferred//name").each_with_index do |p, i|
            i.zero? and term = domain_prefix(n, p.text)
            i.positive? and res[domain_prefix(n, p.text)] = term
          end
          n.xpath("./admitted//name").each do |p|
            res[domain_prefix(n, p.text)] = term
          end
        end
      end

      def norm_id_memorize(node, res_table, selector, prefix, use_domain)
        norm_id_memorize_init(node, res_table, selector, prefix, use_domain)
        memorize_other_pref_terms(node, res_table, selector, use_domain)
      end

      def norm_id_memorize_init(node, res_table, selector, prefix, use_domain)
        term_text = normalize_ref_id(node, selector, use_domain) or return
        unless AUTOMATIC_GENERATED_ID_REGEXP.match(node["id"]).nil? &&
            !node["id"].nil?
          id = unique_text_id(term_text, prefix)
          node["id"] = id
          @idhash[id] = true
        end
        res_table[term_text] = node["id"]
      end

      def memorize_other_pref_terms(node, res_table, text_selector, use_domain)
        node.xpath(text_selector).each_with_index do |p, i|
          i.positive? or next
          res_table[normalize_ref_id1(p, use_domain ? node : nil)] = node["id"]
        end
      end

      def domain_prefix(node, term)
        d = node&.at(".//domain") or return term
        "<#{d.text}> #{term}"
      end

      def normalize_ref_id(node, selector, use_domain)
        term = node.at(selector) or return nil
        normalize_ref_id1(term, use_domain ? node : nil)
      end

      def normalize_ref_id1(term, node = nil)
        t = term.dup
        t.xpath(".//index").map(&:remove)
        ret = t.text.strip
        node and ret = domain_prefix(node, ret)
        Metanorma::Utils::to_ncname(ret.gsub(/[[:space:]]+/, "-"))
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
