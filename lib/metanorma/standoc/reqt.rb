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

      def requirement(node, obligation)
        model = node.attr("model")&.to_sym || default_requirement_model
        attrs = keep_attrs(node).merge(id_unnum_attrs(node))
          .merge(model: model)
        @reqt_model = @reqt_models.model(model)
        ret = @reqt_model.requirement(node, obligation, attrs)
        @reqt_model = nil
        ret
      end
    end
  end
end
