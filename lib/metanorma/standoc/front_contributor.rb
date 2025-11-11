require_relative "./front_organisation"
require_relative "./front_committee"

module Metanorma
  module Standoc
    module Front
      def metadata_author(node, xml)
        org_author(node, xml)
        personal_author(node, xml)
        corporate_author = node.attr("corporate-author") ||
          node.attr("publisher") || default_publisher
        committee_contributors(node, xml, corporate_author, {})
      end

      def org_author(node, xml)
        if node.attr("corporate-author")
          org_contributor(node, xml, { source: ["corporate-author"],
                                       role: "author" })
        else
          org_contributor(node, xml,
                          { source: ["publisher", "pub"], role: "author",
                            default: default_publisher })
        end
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
        desc = node.attr("role-description#{suffix}")
        contrib.role type: type do |r|
          add_noko_elem(r, "description", desc)
        end
      end

      def personal_contact(node, suffix, person)
        node.attr("phone#{suffix}") and
          add_noko_elem(person, "phone", node.attr("phone#{suffix}"))
        node.attr("fax#{suffix}") and
          add_noko_elem(person, "phone", node.attr("fax#{suffix}"), type: "fax")
        node.attr("email#{suffix}") and
          add_noko_elem(person, "email", node.attr("email#{suffix}"))
        node.attr("contributor-uri#{suffix}") and
          add_noko_elem(person, "uri", node.attr("contributor-uri#{suffix}"))
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
            add_noko_elem(n, "completename", node.attr("fullname#{suffix}"))
          else
            add_noko_elem(n, "forename", node.attr("givenname#{suffix}"))
            add_noko_elem(n, "initial", node.attr("initials#{suffix}"))
            add_noko_elem(n, "surname", node.attr("surname#{suffix}"))
          end
        end
      end

      def person_credentials(node, _xml, suffix, person)
        add_noko_elem(person, "credentials",
                      node.attr("contributor-credentials#{suffix}"))
      end

      def person_affiliation(node, _xml, suffix, person)
        aff = node.attr("affiliation#{suffix}")
        pos = node.attr("contributor-position#{suffix}")
        (aff || pos) and person.affiliation do |a|
          add_noko_elem(a, "name", pos)
          aff and a.organization do |o|
            person_organization(node, suffix, o)
          end
        end
      end

      def metadata_publisher(node, xml)
        o = { source: ["publisher", "pub"], role: "publisher",
              default: default_publisher }
        org_contributor(node, xml, o)
      end

      def metadata_sponsor(node, xml)
        o = { source: ["sponsor"], role: "enabler" }
        org_contributor(node, xml, o)
        o = { source: ["authorizer"], role: "authorizer" }
        org_contributor(node, xml, o)
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
            (p[:name].is_a?(String) && p[:name].match(/\p{L}/).nil?) or
              c.owner do |owner|
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
