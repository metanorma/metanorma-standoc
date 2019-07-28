require_relative "./standoc/processor"
require_relative "./standoc/requirement"
require_relative "./standoc/latexml_requirement"

module Metanorma
  module Standoc
    Requirements = {
      latexml: LatexmlRequirement.new
    }
  end
end
