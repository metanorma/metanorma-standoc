require "metanorma/standoc/utils"

module Metanorma
  module Standoc
    # Intelligent term lookup xml modifier
    class TermLookupCleanup
      AUTO_GEN_ID_REGEXP = /\A_/

      attr_reader :xmldoc, :lookup, :log

      def initialize(xmldoc, log)
        @xmldoc = xmldoc
        @log = log
        @lookup = { term: {}, symbol: {}, sec2prim: {} }
        @idhash = {}
        @unique_designs = {}
        @c = HTMLEntities.new
        @terms_tags = xmldoc.xpath("//terms").each_with_object({}) do |t, m|
          #m[t["id"]] = true
          m[t["anchor"]] = true
        end
      end

      def call
        #require "debug"; binding.b
        @idhash = populate_idhash
        @unique_designs = unique_designators
        @lookup = replace_automatic_generated_ids_terms
        set_termxref_tags_target
        concept_cleanup
        related_cleanup
        remove_missing_refs
        concept_cleanup2
        anchor_to_id
      end

      private

      def unique_designators
        ret = xmldoc
          .xpath("//preferred/expression/name | //admitted/expression/name | " \
                 "//deprecates/expression/name").each_with_object({}) do |n, m|
          m[n.text] ||= 0
          m[n.text] += 1
        end
        ret.each { |k, v| v == 1 or ret.delete(k) }
        ret
      end

      def concept_cleanup
        xmldoc.xpath("//concept").each do |n|
          refterm = n.at("./refterm") or next
          lookup = norm_ref_id_text(refterm.text.strip)
          p = @lookup[:sec2prim][lookup] and refterm.children = @c.encode(p)
        end
      end

      def concept_cleanup2
        xmldoc.xpath("//concept").each { |n| n.delete("type") }
      end

      def related_cleanup
        xmldoc.xpath("//related").each do |n|
          refterm = n.at("./refterm") or next
          repl = "<preferred><expression>" \
            "<name>#{refterm.children.to_xml}</name></expression></preferred>"
          lookup = norm_ref_id_text(refterm.text.strip)
          p = @lookup[:sec2prim][lookup] and refterm.children = @c.encode(p)
          p || @lookup[:term][lookup] and
            refterm.replace(repl)
        end
      end

      def populate_idhash
        #xmldoc.xpath("//*[@id]").each_with_object({}) do |n, mem|
        xmldoc.xpath("//*[@anchor]").each_with_object({}) do |n, mem|
          #/^(term|symbol)-/.match?(n["id"]) or next
          /^(term|symbol)-/.match?(n["anchor"]) or next
          #mem[n["id"]] = true
          mem[n["anchor"]] = true
        end
      end

      def set_termxref_tags_target
        xmldoc.xpath("//termxref").each do |node|
          target = norm_ref_id1(node)
          x = node.at("../xrefrender") and modify_ref_node(x, target)
          node.name = "refterm"
        end
      end

      def remove_missing_refs
        xmldoc.xpath("//refterm").each do |node|
          remove_missing_ref?(node) or next
          lookup_refterm(node)
        end
      end

      def remove_missing_ref?(node)
        node.at("../eref | ../termref") and return false
        xref = node.at("../xref") or return true
        xref["target"] && !xref["target"].empty? and return false
        xref.remove # if xref supplied by user, we won't delete
        true
      end

      def lookup_refterm(node)
        target = norm_ref_id1(node)
        if @lookup[:term][target].nil? && @lookup[:symbol][target].nil?
          remove_missing_ref(node, target)
        else
          x = node.at("../xrefrender") and x.name = "xref"
        end
      end

      def remove_missing_ref(node, target)
        if node.at("./parent::concept[@type = 'symbol']")
          log.add("AsciiDoc Input", node,
                  remove_missing_ref_msg(node, target, :symbol), severity: 1)
          remove_missing_ref_term(node, target, "symbol")
        else
          log.add("AsciiDoc Input", node,
                  remove_missing_ref_msg(node, target, :term), severity: 1)
          remove_missing_ref_term(node, target, "term")
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
        target2 = "_#{target.downcase.tr('-', '_')}"
        if @terms_tags[target] || @terms_tags[target2]
          ret.strip!
          ret += ". Did you mean to point to a subterm?"
        end
        ret
      end

      def remove_missing_ref_term(node, target, type)
        node.name = "strong"
        node.xpath("../xrefrender | ../xref").each(&:remove)
        display = node.at("../renderterm")&.remove&.children
        display = [] if display.nil? || display.to_xml == node.text
        d = display.empty? ? "" : ", display <tt>#{display.to_xml}</tt>"
        node.children = "#{type} <tt>#{@c.encode(node.text)}</tt>#{d} " \
                        "not resolved via ID <tt>#{target}</tt>"
      end

      def modify_ref_node(node, target)
        node.name = "xref"
        s = @lookup[:symbol][target]
        t1 = @lookup[:sec2prim][target] and target = norm_ref_id1(t1)
        t = @lookup[:term][target]
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
        { term: r, symbol: s, sec2prim: pref_secondary2primary }
      end

      def pref_secondary2primary
        xmldoc.xpath("//term").each.with_object({}) do |n, res|
          primary = domain_prefix(n, n.at("./preferred//name")&.text)
          pref_secondary2primary_preferred(n, res, primary)
          pref_secondary2primary_admitted(n, res, primary)
        end
      end

      def pref_secondary2primary_preferred(term, res, primary)
        term.xpath("./preferred//name").each_with_index do |p, i|
          t = p.text.strip
          i.positive? and
            res[norm_ref_id_text(domain_prefix(term, t))] = primary
          @unique_designs[t] && term.at(".//domain") and
            res[norm_ref_id_text(t)] = primary
        end
      end

      def pref_secondary2primary_admitted(term, res, primary)
        term.xpath("./admitted//name").each do |p|
          t = p.text.strip
          res[norm_ref_id_text(domain_prefix(term, t))] = primary
          @unique_designs[t] && term.at(".//domain") and
            res[norm_ref_id_text(t)] = primary
        end
      end

      def norm_id_memorize(node, res_table, selector, prefix, use_domain)
        norm_id_memorize_init(node, res_table, selector, prefix, use_domain)
        memorize_other_pref_terms(node, res_table, selector, use_domain)
      end

      def norm_id_memorize_init(node, res_table, selector, prefix, use_domain)
        term_text = norm_ref_id(node, selector, use_domain) or return
        #unless AUTO_GEN_ID_REGEXP.match(node["id"]).nil? && !node["id"].nil?
        unless AUTO_GEN_ID_REGEXP.match(node["anchor"]).nil? && !node["anchor"].nil?
          id = unique_text_id(term_text, prefix)
          #node["id"] = id
          node["anchor"] = id
          @idhash[id] = true
        end
        #res_table[term_text] = node["id"]
        res_table[term_text] = node["anchor"]
      end

      def memorize_other_pref_terms(node, res_table, text_selector, use_domain)
        node.xpath(text_selector).each_with_index do |p, i|
          i.positive? or next
          #res_table[norm_ref_id1(p, use_domain ? node : nil)] = node["id"]
          res_table[norm_ref_id1(p, use_domain ? node : nil)] = node["anchor"]
        end
      end

      def domain_prefix(node, term)
        d = node&.at(".//domain") or return term
        "<#{d.text}> #{term}"
      end

      def norm_ref_id(node, selector, use_domain)
        term = node.at(selector) or return nil
        norm_ref_id1(term, use_domain ? node : nil)
      end

      def norm_ref_id1(term, node = nil)
        t = term.dup
        if t.is_a?(String) then ret = t
        else
          t.xpath(".//index").map(&:remove)
          ret = asciimath_key(t).text.strip
        end
        node and ret = domain_prefix(node, ret)
        norm_ref_id_text(ret)
      end

      def norm_ref_id_text(text)
        Metanorma::Utils::to_ncname(text.gsub(/[[:space:]]+/, "-"))
      end

      def unique_text_id(text, prefix)
        @idhash["#{prefix}-#{text}"] or return "#{prefix}-#{text}"
        (1..Float::INFINITY).lazy.each do |index|
          @idhash["#{prefix}-#{text}-#{index}"] or
            break("#{prefix}-#{text}-#{index}")
        end
      end

      def anchor_to_id
        xmldoc.xpath("//*[@anchor]").each do |n|
          /^(term|symbol)-/.match?(n["anchor"]) or next
          n["id"] ||= "_#{UUIDTools::UUID.random_create}"
        end
      end

      include ::Metanorma::Standoc::Utils
    end
  end
end
