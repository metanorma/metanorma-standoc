require "htmlentities"
require "uri"
require "mime/types"
require "base64"

module Asciidoctor
  module Standoc
    module Blocks
      def reqt_subpart(name)
        %w(specification measurement-target verification import label
           component subject inherit classification title).include? name
      end

      def reqt_subpart_attrs(node, name)
        attr_code(keep_attrs(node)
          .merge(exclude: node.option?("exclude"),
                 type: node.attr("type"),
                 class: name == "component" ? node.attr("class") : nil))
      end

      def requirement_subpart(node)
        name = node.role || node.attr("style")
        noko do |xml|
          xml.send name, **reqt_subpart_attrs(node, name) do |o|
            o << node.content
          end
        end
      end

      def req_classif_parse(classif)
        ret = []
        HTMLEntities.new.decode(classif).split(/;\s*/).each do |c|
          c1 = c.split(/:\s*/)
          next unless c1.size == 2

          c1[1].split(/,\s*/).each { |v| ret << [c1[0], v] }
        end
        ret
      end

      def requirement_classification(classif, out)
        req_classif_parse(classif).each do |r|
          out.classification do |c|
            c.tag { |t| t << r[0] }
            c.value { |v| v << r[1] }
          end
        end
      end

      def reqt_attrs(node)
        attr_code(keep_attrs(node).merge(id_unnum_attrs(node)).merge(
                    id: Metanorma::Utils::anchor_or_uuid(node),
                    unnumbered: node.option?("unnumbered") ? "true" : nil,
                    number: node.attr("number"),
                    subsequence: node.attr("subsequence"),
                    obligation: node.attr("obligation"),
                    filename: node.attr("filename"),
                    type: node.attr("type"),
                    model: node.attr("model"),
                  ))
      end

      def requirement_elems(node, out)
        node.title and out.title { |t| t << node.title }
        a = node.attr("label") and out.label do |l|
          l << a
        end
        a = node.attr("subject") and out.subject do |s|
          s << a
        end
        HTMLEntities.new.decode(node.attr("inherit"))&.split(/;\s*/)
          &.each do |i|
          out.inherit { |inh| inh << i }
        end
        classif = node.attr("classification") and
          requirement_classification(classif, out)
      end

      def requirement(node, obligation)
        noko do |xml|
          xml.send obligation, **reqt_attrs(node) do |ex|
            requirement_elems(node, ex)
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end
    end
  end
end
