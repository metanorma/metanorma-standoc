module Metanorma
  module Standoc
    module Front
      def organization(org, orgname, node = nil, default_org = nil, attrs = {})
        orgname, abbr = org_name_and_abbrev(attrs, orgname)
        add_noko_elem(org, "name", orgname)
        default_org && (a = node&.attr("subdivision")) && !attrs[:subdiv] and
          subdivision(a, node&.attr("subdivision-abbr"), org)
        a = attrs[:subdiv] and subdivision(a, nil, org)
        add_noko_elem(org, "abbreviation", abbr)
      end

      def org_name_and_abbrev(org, orgname)
        if org[:abbrev]
          [orgname, org[:abbrev]]
        else
          abbrevs = org_abbrev
          n = abbrevs.invert[orgname] and orgname = n
          [orgname, org_abbrev[orgname]]
        end
      end

      def subdivision(attr, abbr, org)
        abbrs = csv_split(abbr) || []
        subdivs = csv_split(attr, ";")
        subdivs.size == abbrs.size or abbrs = []
        subdivs.each_with_index do |s, i|
          subdivision1(s, abbrs[i], org)
        end
      end

      def subdivision1(attr, abbr, org)
        m = csv_split(attr, ",").map do |s1|
          t, v = s1.split(":", 2).map(&:strip)
          if v.nil?
            v = t
            t = nil
          end
          { type: t, value: v }
        end
        abbr and m[0][:abbr] = abbr
        subdiv_build(m, org)
      end

      def subdiv_build(list, org)
        list.empty? and return
        org.subdivision **attr_code(type: list[0][:type]) do |s|
          add_noko_elem(s, "name", list[0][:value])
          subdiv_build(list[1..], s)
          add_noko_elem(s, "abbreviation", list[0][:abbr])
        end
      end

      def org_address(org, xml)
        p = org[:address] and xml.address do |ad|
          add_noko_elem(ad, "formattedAddress", p.gsub(/ \+\n/, "<br/>"))
        end
        org_contact(org, xml)
      end

      def org_contact(org, xml)
        add_noko_elem(xml, "phone", org[:phone])
        add_noko_elem(xml, "phone", org[:fax], type: "fax")
        add_noko_elem(xml, "email", org[:email])
        add_noko_elem(xml, "uri", org[:uri])
      end

      def person_organization(node, suffix, xml)
        add_noko_elem(xml, "name", node.attr("affiliation#{suffix}"))
        add_noko_elem(xml, "abbreviation",
                      node.attr("affiliation_abbrev#{suffix}"))
        a = node.attr("affiliation_subdiv#{suffix}") and
          subdivision(a, nil, xml)
        person_address(node, suffix, xml)
        person_org_logo(node, suffix, xml)
      end

      def person_address(node, suffix, xml)
        if node.attr("address#{suffix}")
          xml.address do |ad|
            add_noko_elem(ad, "formattedAddress",
                          node.attr("address#{suffix}").gsub(/ \+\n/, "<br/>"))
          end
        elsif node.attr("country#{suffix}") || node.attr("city#{suffix}")
          person_address_components(node, suffix, xml)
        end
      end

      def person_address_components(node, suffix, xml)
        xml.address do |ad|
          %w(street city state country postcode).each do |k|
            add_noko_elem(ad, k, node.attr("#{k}#{suffix}"))
          end
        end
      end

      def person_org_logo(node, suffix, xml)
        p = node.attr("affiliation_logo#{suffix}") and org_logo(xml, p)
      end

      def org_logo(xml, logo)
        logo and xml.logo do |l|
          l.image src: logo, mimetype: image_mimetype(logo)
        end
      end

      def default_publisher
        nil
      end

      def org_abbrev
        {}
      end

      def org_contributor(node, xml, opts)
        org_attrs_parse(node, opts).each do |o|
          xml.contributor do |c|
            org_contributor_role(c, o)
            c.organization do |a|
              org_organization(node, a, o)
            end
          end
        end
      end

      def org_contributor_role(xml, org)
        xml.role type: org[:role] do |r|
          add_noko_elem(r, "description", org[:desc])
        end
      end

      def org_organization(node, xml, org)
        if org[:committee]
          contrib_committee_build(xml, org[:agency], org)
        else
          organization(xml, org[:name], node, !node.attr("publisher"), org)
          org_address(org, xml)
          org_logo(xml, org[:logo])
        end
      end

      def org_attrs_parse_core(node, opts)
        source = opts[:source]&.detect { |s| node.attr(s) }
        org_attrs_simple_parse(node, opts, source) ||
          org_attrs_complex_parse(node, opts, source)
      end

      def org_attrs_simple_parse(node, opts, source)
        !source and return org_attrs_simple_parse_no_source(node, opts)
        orgs = csv_split(node.attr(source))
        orgs.size > 1 and return orgs.map do |o|
          { name: o, role: opts[:role], desc: opts[:desc] }
        end
        nil
      end

      def org_attrs_simple_parse_no_source(node, opts)
        !opts[:default] && !opts[:name] and return []
        [{ name: opts[:name] || opts[:default],
           role: opts[:role], desc: opts[:desc] }
          .compact.merge(extract_org_attrs_address(node, opts, ""))]
      end

      def org_attrs_complex_parse(node, opts, source)
        i = 1
        suffix = ""
        ret = []
        while committee_number_or_name?(node, source, suffix)
          ret << extract_org_attrs_complex(node, opts, source, suffix)
          i += 1
          suffix = "_#{i}"
        end
        ret
      end

      def extract_org_attrs_complex(node, opts, source, suffix)
        n = node.attr("#{source}-number#{suffix}") # for committees
        t = committee_ident(node.attr("#{source}-type#{suffix}"), n, source)
        { name: node.attr(source + suffix), ident: t,
          abbrev: node.attr("#{source}_abbr#{suffix}"),
          role: opts[:role], desc: opts[:desc],
          type: node.attr("#{source}-type#{suffix}"),
          subdiv: node.attr("#{source}_subdivision#{suffix}"),
          logo: node.attr("#{source}_logo#{suffix}") }.compact
          .merge(extract_org_attrs_address(node, opts, suffix))
      end

      def committee_abbrevs
        { "technical-committee" => "TC" }
      end

      def committee_ident(type, number, level)
        number.nil? || number.empty? and return
        type ||= committee_abbrevs[level]
        type == "Other" and type = ""
        "#{type} #{number}".strip
      end

      def extract_org_attrs_address(node, opts, suffix)
        %w(address phone fax email uri).each_with_object({}) do |a, m|
          opts[:source]&.each do |s|
            p = node.attr("#{s}-#{a}#{suffix}") and
              m[a.to_sym] = p
          end
        end
      end
    end
  end
end
