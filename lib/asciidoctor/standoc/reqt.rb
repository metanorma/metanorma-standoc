require "htmlentities"
require "uri"
require "mime/types"
require "base64"

module Asciidoctor
  module Standoc
    module Blocks
      def reqt_subpart(x)
        %w(specification measurement-target verification import label
             subject inherit classification title).include? x
      end

      def reqt_subpart_attrs(node)
        attr_code(keep_attrs(node).merge(exclude: node.option?("exclude"),
                                     type: node.attr("type")))
      end

      def requirement_subpart(node)
        name = node.role || node.attr("style")
        noko do |xml|
          xml.send name, **reqt_subpart_attrs(node) do |o|
            o << node.content
          end
        end
      end

      def req_classif_parse(classif)
        ret = []
        HTMLEntities.new.decode(classif).split(/;\s*/).each do |c|
          c1 = c.split(/:\s*/)
          next unless c1.size == 2
          c1[1].split(/,\s*/).each { |v| ret << [ c1[0], v ] }
        end
        ret
      end

      def requirement_classification(classif, ex)
        req_classif_parse(classif).each do |r|
          ex.classification do |c|
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

      def requirement(node, obligation)
        classif = node.attr("classification")
        noko do |xml|
          xml.send obligation, **reqt_attrs(node) do |ex|
            node.title and ex.title { |t| t << node.title }
            node.attr("label") and ex.label { |l| l << node.attr("label") }
            node.attr("subject") and ex.subject { |s| s << node.attr("subject") }
            i = HTMLEntities.new.decode(node.attr("inherit"))
            i&.split(/;\s*/)&.each do |i|
              ex.inherit { |inh| inh << i }
            end
            requirement_classification(classif, ex) if classif
            wrap_in_para(node, ex)
          end
        end.join("\n")
      end
    end
  end
end
