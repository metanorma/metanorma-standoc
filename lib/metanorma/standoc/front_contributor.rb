require "date"
require "nokogiri"
require "htmlentities"
require "pathname"
require "csv"

module Metanorma
  module Standoc
    module Front
      def committee_component(compname, node, out)
        out.send compname.gsub(/-/, "_"), node.attr(compname),
                 **attr_code(number: node.attr("#{compname}-number"),
                             type: node.attr("#{compname}-type"))
        i = 2
        while node.attr(compname + "_#{i}")
          out.send compname.gsub(/-/, "_"), node.attr(compname + "_#{i}"),
                   **attr_code(number: node.attr("#{compname}-number_#{i}"),
                               type: node.attr("#{compname}-type_#{i}"))
          i += 1
        end
      end

      def organization(org, orgname, is_pub, node = nil, default_org = nil)
        abbrevs = org_abbrev
        n = abbrevs.invert[orgname] and orgname = n
        org.name orgname
        default_org and a = node.attr("subdivision") and org.subdivision a
        abbr = org_abbrev[orgname]
        default_org && b = node.attr("subdivision-abbr") and abbr = b
        abbr and org.abbreviation abbr
        is_pub && node and org_address(node, org)
      end

      def org_address(node, person)
        node.attr("pub-address") and person.address do |ad|
          ad.formattedAddress do |f|
            f << node.attr("pub-address").gsub(/ \+\n/, "<br/>")
          end
        end
        node.attr("pub-phone") and person.phone node.attr("pub-phone")
        node.attr("pub-fax") and
          person.phone node.attr("pub-fax"), type: "fax"
        node.attr("pub-email") and person.email node.attr("pub-email")
        node.attr("pub-uri") and person.uri node.attr("pub-uri")
      end

      def metadata_author(node, xml)
        csv_split(node.attr("publisher") || default_publisher || "")
          &.each do |p|
          xml.contributor do |c|
            c.role type: "author"
            c.organization do |a|
              organization(a, p, false, node, !node.attr("publisher"))
            end
          end
        end
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

      def default_publisher
        nil
      end

      def org_abbrev
        {}
      end

      def metadata_publisher(node, xml)
        publishers = node.attr("publisher") || default_publisher || return
        csv_split(publishers)&.each do |p|
          xml.contributor do |c|
            c.role type: "publisher"
            c.organization do |a|
              organization(a, p, true, node, !node.attr("publisher"))
            end
          end
        end
      end

      def metadata_copyright(node, xml)
        pub = node.attr("copyright-holder") || node.attr("publisher")
        csv_split(pub || default_publisher || "-")&.each do |p|
          xml.copyright do |c|
            c.from (node.attr("copyright-year") || Date.today.year)
            p.match(/[A-Za-z]/).nil? or c.owner do |owner|
              owner.organization do |a|
                organization(a, p, true, node, !pub)
              end
            end
          end
        end
      end
    end
  end
end
