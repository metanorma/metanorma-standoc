require "date"
require "pathname"
require "csv"

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
        default_org and a = node.attr("subdivision") and org.subdivision a
        abbr = org_abbrev[orgname]
        default_org && b = node.attr("subdivision-abbr") and abbr = b
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

      def metadata_author(node, xml)
        org_contributor(node, xml,
                        { source: ["publisher", "pub"], role: "author",
                          default: default_publisher })
        personal_author(node, xml)
      end

      def personal_author(node, xml)
        (node.attr("fullname") || node.attr("surname")) and
          personal_author1(node, xml, "")
        i = 2
        while node.attr("fullname_#{i}") || node.attr("surname_#{i}")
          personal_author1(node, xml, "_#{i}")
          i += 1
        end
      end

      def personal_role(node, contrib, suffix)
        type = node.attr("role#{suffix}")&.downcase || "author"
        contrib.role type: type
      end

      def personal_contact(node, suffix, person)
        node.attr("phone#{suffix}") and person.phone node.attr("phone#{suffix}")
        node.attr("fax#{suffix}") and
          person.phone node.attr("fax#{suffix}"), type: "fax"
        node.attr("email#{suffix}") and person.email node.attr("email#{suffix}")
        node.attr("contributor-uri#{suffix}") and
          person.uri node.attr("contributor-uri#{suffix}")
      end

      def personal_author1(node, xml, suffix)
        xml.contributor do |c|
          personal_role(node, c, suffix)
          c.person do |p|
            person_name(node, xml, suffix, p)
            person_credentials(node, xml, suffix, p)
            person_affiliation(node, xml, suffix, p)
            personal_contact(node, suffix, p)
          end
        end
      end

      def person_name(node, _xml, suffix, person)
        person.name do |n|
          if node.attr("fullname#{suffix}")
            n.completename node.attr("fullname#{suffix}")
          else
            n.forename node.attr("givenname#{suffix}")
            n.initial node.attr("initials#{suffix}")
            n.surname node.attr("surname#{suffix}")
          end
        end
      end

      def person_credentials(node, _xml, suffix, person)
        c = node.attr("contributor-credentials#{suffix}") and
          person.credentials c
      end

      def person_affiliation(node, _xml, suffix, person)
        aff = node.attr("affiliation#{suffix}")
        pos = node.attr("contributor-position#{suffix}")
        (aff || pos) and person.affiliation do |a|
          pos and a.name { |n| n << pos }
          aff and a.organization do |o|
            person_organization(node, suffix, o)
          end
        end
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
          s = node.attr("street#{suffix}") and ad.street s
          s = node.attr("city#{suffix}") and ad.city s
          s = node.attr("state#{suffix}") and ad.state s
          s = node.attr("country#{suffix}") and ad.country s
          s = node.attr("postcode#{suffix}") and ad.postcode s
        end
      end

      def person_org_logo(node, suffix, xml)
        p = node.attr("affiliation_logo#{suffix}") or return
        org_logo(xml, p)
      end

      def org_logo(xml, logo)
        logo or return
        xml.logo do |l|
          l.image src: logo
        end
      end

      def default_publisher
        nil
      end

      def org_abbrev
        {}
      end

      def metadata_publisher(node, xml)
        o = { source: ["publisher", "pub"], role: "publisher",
              default: default_publisher }
        org_contributor(node, xml, o)
      end

      def metadata_sponsor(node, xml)
        o = { source: ["sponsor"], role: "enabler" }
        org_contributor(node, xml, o)
      end

      def org_contributor(node, xml, opts)
        org_attrs_parse(node, opts).each do |o|
          xml.contributor do |c|
            c.role type: o[:role] do |r|
              o[:desc] and r << o[:desc]
            end
            c.organization do |a|
              org_organization(node, a, o)
            end
          end
        end
      end

      def org_organization(node, xml, org)
        organization(xml, org[:name], node, !node.attr("publisher"))
        org_address(org, xml)
        org_logo(xml, org[:logo])
      end

      def org_attrs_parse(node, opts)
        source = opts[:source].detect { |s| node.attr(s) }
        org_attrs_simple_parse(node, opts, opts[:role], source) ||
          org_attrs_complex_parse(node, opts, opts[:role], source)
      end

      def org_attrs_simple_parse(node, opts, role, source)
        !source && !opts[:default] && !opts[:name] and return []
        !source and return [{ name: opts[:name] || opts[:default], role: role }
            .merge(extract_org_attrs_address(node, opts, ""))]
        orgs = csv_split(node.attr(source))
        orgs.size > 1 and return orgs.map { |o| { name: o, role: role } }
        nil
      end

      def org_attrs_complex_parse(node, opts, role, source)
        i = 1
        suffix = ""
        ret = []
        while node.attr(source + suffix)
          ret << extract_org_attrs_complex(node, opts, role, source, suffix)
          i += 1
          suffix = "_#{i}"
        end
        ret
      end

      def extract_org_attrs_complex(node, opts, role, source, suffix)
        { name: node.attr(source + suffix), role: role,
          logo: node.attr("#{source}_logo#{suffix}") }.compact
          .merge(extract_org_attrs_address(node, opts, suffix))
      end

      def extract_org_attrs_address(node, opts, suffix)
        %w(address phone fax email uri).each_with_object({}) do |a, m|
          opts[:source].each do |s|
            p = node.attr("#{s}-#{a}#{suffix}") and
              m[a.to_sym] = p
          end
        end
      end

      def copyright_parse(node)
        opt = { source: ["copyright-holder", "publisher", "pub"],
                role: "publisher", default: default_publisher }
        ret = org_attrs_parse(node, opt)
        ret.empty? and ret = [{ name: "-" }]
        ret
      end

      def metadata_copyright(node, xml)
        copyright_parse(node).each do |p|
          xml.copyright do |c|
            c.from (node.attr("copyright-year") || Date.today.year)
            p[:name].match(/[A-Za-z]/).nil? or c.owner do |owner|
              owner.organization do |a|
                org_organization(node, a, p)
              end
            end
          end
        end
      end
    end
  end
end
