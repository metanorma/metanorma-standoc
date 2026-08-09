# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Blocks
      autoload :AmendBlock, "#{__dir__}/blocks/amend_block"
      autoload :AmendContentBlock, "#{__dir__}/blocks/amend_content_block"
      autoload :BlockSourceElement, "#{__dir__}/blocks/block_source"
      autoload :SourceOriginElement, "#{__dir__}/blocks/source_origin_element"
      autoload :AutoNumber, "#{__dir__}/blocks/auto_number"
      autoload :ChangeType, "#{__dir__}/blocks/change_type"
      autoload :ElementName, "#{__dir__}/blocks/element_name"
      autoload :Form, "#{__dir__}/blocks/form"
      autoload :ImageMapAreaType, "#{__dir__}/blocks/image_map_area_type"
      autoload :ImageMapAreaTypeType,
               "#{__dir__}/blocks/image_map_area_type_type"
      autoload :ImageMapBlock, "#{__dir__}/blocks/image_map_block"
      autoload :ImageMapCoords, "#{__dir__}/blocks/image_map_coords"
      autoload :ImageMapRadius, "#{__dir__}/blocks/image_map_radius"
      autoload :MultilingualRenderingType,
               "#{__dir__}/blocks/multilingual_rendering_type"
      autoload :Passthrough, "#{__dir__}/blocks/passthrough"
      autoload :StandardAdmonitionBlock,
               "#{__dir__}/blocks/standard_admonition_block"
      autoload :StandardBlock, "#{__dir__}/blocks/standard_block"
      autoload :StandardBlockNoNotes,
               "#{__dir__}/blocks/standard_block_no_notes"
      autoload :StandardExampleBlock, "#{__dir__}/blocks/standard_example_block"
      autoload :StandardFigureBlock, "#{__dir__}/blocks/standard_figure_block"
      autoload :StandardFormulaBlock, "#{__dir__}/blocks/standard_formula_block"
      autoload :StandardNoteBlock, "#{__dir__}/blocks/standard_note_block"
      autoload :StandardParagraphBlock,
               "#{__dir__}/blocks/standard_paragraph_block"
      autoload :StandardQuoteBlock, "#{__dir__}/blocks/standard_quote_block"
      autoload :StandardSourcecodeBlock,
               "#{__dir__}/blocks/standard_sourcecode_block"
      autoload :StandardTableBlock, "#{__dir__}/blocks/standard_table_block"
      autoload :ClassificationValue,
               "#{__dir__}/blocks/requirement_model"
      autoload :RequirementClassification,
               "#{__dir__}/blocks/requirement_model"
      autoload :RequirementDescription,
               "#{__dir__}/blocks/requirement_model"
      autoload :RequirementInherit,
               "#{__dir__}/blocks/requirement_model"
      autoload :RequirementBase,
               "#{__dir__}/blocks/requirement_model"
      autoload :RequirementModel,
               "#{__dir__}/blocks/requirement_model"
      autoload :RecommendationModel,
               "#{__dir__}/blocks/requirement_model"
      autoload :PermissionModel,
               "#{__dir__}/blocks/requirement_model"
      autoload :SvgMapBlock, "#{__dir__}/blocks/svg_map_block"
      autoload :SvgTargetType, "#{__dir__}/blocks/svg_target_type"
      autoload :TableCol, "#{__dir__}/blocks/table_col"
      autoload :ToC, "#{__dir__}/blocks/to_c"
    end
  end
end
