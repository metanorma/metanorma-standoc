module Metanorma
  module Standoc
    module Front
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

      def organization(org, orgname, node = nil, default_org = nil)
        abbrevs = org_abbrev
        n = abbrevs.invert[orgname] and orgname = n
        org.name orgname
        default_org and a = node&.attr("subdivision") and org.subdivision a
        abbr = org_abbrev[orgname]
        default_org && b = node&.attr("subdivision-abbr") and abbr = b
        abbr and org.abbreviation abbr
      end

      def org_address(org, xml)
        p = org[:address] and xml.address do |ad|
          ad.formattedAddress do |f|
            f << p.gsub(/ \+\n/, "<br/>")
          end
        end
        p = org[:phone] and xml.phone p
        p = org[:fax] and xml.phone p, type: "fax"
        p = org[:email] and xml.email p
        p = org[:uri] and xml.uri p
      end

      def person_organization(node, suffix, xml)
        xml.name node.attr("affiliation#{suffix}")
        abbr = node.attr("affiliation_abbrev#{suffix}") and
          xml.abbreviation abbr
        csv_split(node.attr("affiliation_subdiv#{suffix}"))&.each do |s|
          xml.subdivision s
        end
        person_address(node, suffix, xml)
        person_org_logo(node, suffix, xml)
      end

      def person_address(node, suffix, xml)
        if node.attr("address#{suffix}")
          xml.address do |ad|
            ad.formattedAddress do |f|
              f << node.attr("address#{suffix}").gsub(/ \+\n/, "<br/>")
            end
          end
        elsif node.attr("country#{suffix}") || node.attr("city#{suffix}")
          person_address_components(node, suffix, xml)
        end
      end

      def person_address_components(node, suffix, xml)
        xml.address do |ad|
          %w(street city state country postcode).each do |k|
            s = node.attr("#{k}#{suffix}") and ad.send k, s
          end
        end
      end

      def person_org_logo(node, suffix, xml)
        p = node.attr("affiliation_logo#{suffix}") and org_logo(xml, p)
      end

      def org_logo(xml, logo)
        logo and xml.logo do |l|
          l.image src: logo
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
          org[:desc] and r.description do |d|
            d << org[:desc]
          end
        end
      end

      def org_organization(node, xml, org)
        organization(xml, org[:name], node, !node.attr("publisher"))
        org_address(org, xml)
        org_logo(xml, org[:logo])
      end

      def org_attrs_parse(node, opts)
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
        while node.attr(source + suffix)
          ret << extract_org_attrs_complex(node, opts, source, suffix)
          i += 1
          suffix = "_#{i}"
        end
        ret
      end

      def extract_org_attrs_complex(node, opts, source, suffix)
        { name: node.attr(source + suffix),
          role: opts[:role], desc: opts[:desc],
          logo: node.attr("#{source}_logo#{suffix}") }.compact
          .merge(extract_org_attrs_address(node, opts, suffix))
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
