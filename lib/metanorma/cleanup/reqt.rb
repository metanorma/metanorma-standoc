module Metanorma
  module Standoc
    module Reqt
      def requirement_cleanup(xmldoc)
        @reqt_models ||=
          @converter.requirements_processor.new({ default: @default_requirement_model })
        @reqt_models.requirement_cleanup(xmldoc)
      end
    end
  end
end
