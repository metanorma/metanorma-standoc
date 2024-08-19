module Metanorma
  module Standoc
    module Blocks
      def reqt_subpart?(name)
        @reqt_model&.reqt_subpart?(name)
      end

      def requirement_subpart(node)
        @reqt_model.requirement_subpart(node, keep_attrs(node))
      end

      def default_requirement_model
        :default
      end

      def select_requirement_model(node)
        return if @reqt_model

        @reqt_model_name = node.attr("model") || @default_requirement_model
        @reqt_model = @reqt_models.model(@reqt_model_name)
      end

      def requirement(node, obligation, type)
        nested = @reqt_model
        !node.attr("type") &&
          !%w(requirement recommendation permission).include?(type) and
          node.set_attr("type", type)
        attrs = keep_attrs(node).merge(id_unnum_attrs(node))
          .merge(model: @reqt_model_name)
        ret = @reqt_model.requirement(node, obligation, attrs)
        @reqt_model = nil unless nested
        ret
      end

      def requirement_validate(docxml)
        docxml.xpath("//requirement | //recommendation | //permission")
          .each do |r|
          @reqt_models.model(r["model"]).validate(r, @log)
        end
      end
    end
  end
end
