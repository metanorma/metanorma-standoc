require "date"
require "nokogiri"
require "htmlentities"
require "pathname"
require "open-uri"
require "csv"

module Asciidoctor
  module Standoc
    module Front
      def committee_component(compname, node, out)
        out.send compname.gsub(/-/, "_"), node.attr(compname),
          **attr_code(number: node.attr("#{compname}-number"),
                      type: node.attr("#{compname}-type"))
        i = 2
        while node.attr(compname+"_#{i}") do
          out.send compname.gsub(/-/, "_"), node.attr(compname+"_#{i}"),
            **attr_code(number: node.attr("#{compname}-number_#{i}"),
                        type: node.attr("#{compname}-type_#{i}"))
          i += 1
        end
      end

      def organization(org, orgname)
        #require "byebug"; byebug
        abbrevs = org_abbrev
        n = abbrevs.invert[orgname] and orgname = n
        org.name orgname
        a = org_abbrev[orgname] and org.abbreviation a
      end

      # , " => ," : CSV definition does not deal with space followed by quote
      # at start of field
      def csv_split(s, delim = ",")
        CSV.parse_line(s&.gsub(/, "(?!")/, ',"'), liberal_parsing: true,
                       col_sep: delim)&.map { |x| x.strip }
      end

      def metadata_author(node, xml)
        csv_split(node.attr("publisher") || default_publisher || "")&.each do |p|
          xml.contributor do |c|
            c.role **{ type: "author" }
            c.organization { |a| organization(a, p) }
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

      def personal_role(node, c, suffix)
        c.role **{ type: node.attr("role#{suffix}")&.downcase || "author" }
      end

      def personal_contact(node, suffix, p)
        node.attr("phone#{suffix}") and p.phone node.attr("phone#{suffix}")
        node.attr("fax#{suffix}") and
          p.phone node.attr("fax#{suffix}"), **{type: "fax"}
        node.attr("email#{suffix}") and p.email node.attr("email#{suffix}")
        node.attr("contributor-uri#{suffix}") and
          p.uri node.attr("contributor-uri#{suffix}")
      end

      def personal_author1(node, xml, suffix)
        xml.contributor do |c|
          personal_role(node, c, suffix)
          c.person do |p|
            person_name(node, xml, suffix, p)
            person_affiliation(node, xml, suffix, p)
            personal_contact(node, suffix, p)
          end
        end
      end

      def person_name(node, xml, suffix, p)
        p.name do |n|
          if node.attr("fullname#{suffix}")
            n.completename node.attr("fullname#{suffix}")
          else
            n.forename node.attr("givenname#{suffix}")
            n.initial node.attr("initials#{suffix}")
            n.surname node.attr("surname#{suffix}")
          end
        end
      end

      def person_affiliation(node, xml, suffix, p)
        node.attr("affiliation#{suffix}") and p.affiliation do |a|
          a.organization do |o|
            o.name node.attr("affiliation#{suffix}")
            abbr = node.attr("affiliation_abbrev#{suffix}") and
              o.abbreviation abbr
            node.attr("address#{suffix}") and o.address do |ad|
              ad.formattedAddress node.attr("address#{suffix}")
            end
          end
        end
      end

      def default_publisher
        nil
      end

      def org_abbrev
        { }
      end

      def metadata_publisher(node, xml)
        publishers = node.attr("publisher") || default_publisher || return
        csv_split(publishers)&.each do |p|
          xml.contributor do |c|
            c.role **{ type: "publisher" }
            c.organization { |a| organization(a, p) }
          end
        end
      end

      def metadata_copyright(node, xml)
        publishers = node.attr("copyright-holder") || node.attr("publisher") || 
          default_publisher || "-"
        csv_split(publishers)&.each do |p|
          xml.copyright do |c|
            c.from (node.attr("copyright-year") || Date.today.year)
            p.match(/[A-Za-z]/).nil? or c.owner do |owner|
              owner.organization { |o| organization(o, p) }
            end
          end
        end
      end
    end
  end
end
