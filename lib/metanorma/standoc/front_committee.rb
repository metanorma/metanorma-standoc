module Metanorma
  module Standoc
    module Front
      def committee_contributors(node, xml, agency, _opts)
        t = metadata_committee_types(node)
        v = t.first
        if node.attr("#{v}-number") || node.attr(v)
          node.attr(v) or node.set_attr(v, "")
          o = committee_contrib_org_prep(node, v, agency, _opts)
          o[:groups] = t
          org_contributor(node, xml, o)
        end
      end

      def metadata_committee_types(_node)
        %w(technical-committee)
      end

      def committee_contrib_org_prep(node, type, agency, _opts)
        agency_arr, agency_abbrev =
          committee_org_prep_agency(node, type, agency, [], [])
        { source: [type], role: "author",
          default_org: false, committee: true, agency: agency_arr,
          agency_abbrev:,
          desc: type.sub(/^approval-/, "").tr("-", " ").capitalize }.compact
      end

      def committee_org_prep_agency(node, type, agency, agency_arr, agency_abbr)
        i = 1
        suffix = ""
        while node.attr("#{type}-number#{suffix}") ||
            node.attr("#{type}#{suffix}")
          agency_arr << (node.attr("#{type}-agency#{suffix}") || agency)
          agency_abbr << node.attr("#{type}-agency-abbr#{suffix}")
          i += 1
          suffix = "_#{i}"
        end
        [agency_arr, agency_abbr]
      end

      def contrib_committee_build(xml, agency, committee)
        if name = org_abbrev.invert[agency]
          committee[:agency_abbrev] = agency
          agency = name
        end
        xml.name agency
        s = committee
        loop do
          contrib_committee_subdiv(xml, s)
          s = s[:subdiv] or break
        end
        abbr = committee[:agency_abbrev] and xml.abbreviation abbr
        full_committee_id(xml.parent)
      end

      def contrib_committee_subdiv(xml, committee)
        contributors_committees_filter_empty?(committee) and return
        xml.subdivision **attr_code(type: committee[:desc]) do |o|
          o.name committee[:name]
          committee[:abbr] and o.abbreviation committee[:abbr]
          committee[:ident] and o.identifier committee[:ident]
        end
      end

      def full_committee_id(contrib)
        ret = full_committee_agency_id(contrib)
        ids = contrib.xpath("./subdivision").map do |x|
          x.at("./identifier")&.text
        end
        ins = contrib.at("./subdivision/identifier") and
          ins.next = "<identifier type='full'>#{ret}#{ids.join('/')}</identifier>"
      end

      def full_committee_agency_id(contrib)
        agency = contrib.at("./abbreviation")&.text
        ret = agency == default_publisher ? "" : "#{agency} "
        /^\s+/.match?(ret) and ret = ""
        ret
      end

      def committee_component(compname, node, out)
        i = 1
        suffix = ""
        while node.attr(compname + suffix)
          out.send compname.gsub(/-/, "_"), node.attr(compname + suffix),
                   **attr_code(number: node.attr("#{compname}-number#{suffix}"),
                               type: node.attr("#{compname}-type#{suffix}"))
          i += 1
          suffix = "_#{i}"
        end
      end

      def org_attrs_parse(node, opts)
        opts_orig = opts.dup
        ret = []
        ret << org_attrs_parse_core(node, opts)&.map&.with_index do |x, i|
          x.merge(agency: opts.dig(:agency, i),
                  agency_abbrev: opts.dig(:agency_abbrev, i), abbr: opts[:abbr],
                  committee: opts[:committee], default_org: opts[:default_org])
        end
        org_attrs_add_committees(node, ret, opts, opts_orig)
      end

      def org_attrs_add_committees(node, ret, opts, opts_orig)
        opts_orig[:groups]&.each_with_index do |g, i|
          i.zero? and next
          contributors_committees_pad_multiples(ret, node, g)
          opts = committee_contrib_org_prep(node, g, nil, opts_orig)
          ret << org_attrs_parse_core(node, opts)
        end
        contributors_committees_nest1(ret)
      end

      # ensure there is subcommittee, workgroup -number_2, -number_3 etc
      # to parse multiple tech committees
      def contributors_committees_pad_multiples(committees, node, group)
        committees.each_with_index do |_r, j|
          suffix = j.zero? ? "" : "_#{j + 1}"
          node.attr("#{group}#{suffix}") or
            node.set_attr("#{group}#{suffix}", "")
          node.attr("#{group}-number#{suffix}") or
            node.set_attr("#{group}-number#{suffix}", "")
        end
      end

      def contributors_committees_filter_empty?(committee)
        committee[:name].empty? && committee[:ident].nil?
      end

      def contributors_committees_nest1(committees)
        committees.empty? and return committees
        committees = committees.reverse
        committees.each_with_index do |m, i|
          i.zero? and next
          m.each_with_index do |m1, j|
            m1[:subdiv] = committees[i - 1][j]
          end
        end
        committees[-1]
      end
    end
  end
end
