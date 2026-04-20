module Metanorma
  module Standoc
    module Reqt
      def requirement_cleanup(xmldoc)
        @reqt_models ||=
          @conv.requirements_processor.new({ conv: @conv.presentation_xml_converter(Metanorma::Standoc::EmptyAttr.new),
                                             default: @default_requirement_model })
        @reqt_models.requirement_cleanup(xmldoc)
      end
    end
  end
end
