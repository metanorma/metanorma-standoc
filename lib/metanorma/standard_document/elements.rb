# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Elements
      autoload :Add, "#{__dir__}/elements/add"
      autoload :Del, "#{__dir__}/elements/del"
      autoload :FormInput, "#{__dir__}/elements/form_input"
      autoload :Input, "#{__dir__}/elements/input"
      autoload :InputType, "#{__dir__}/elements/input_type"
      autoload :Label, "#{__dir__}/elements/label"
      autoload :Option, "#{__dir__}/elements/option"
      autoload :OrientationType, "#{__dir__}/elements/orientation_type"
      autoload :Select, "#{__dir__}/elements/select"
      autoload :StandardPageBreakElement,
               "#{__dir__}/elements/standard_page_break_element"
      autoload :Textarea, "#{__dir__}/elements/textarea"
    end
  end
end
