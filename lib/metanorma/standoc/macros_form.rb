module Metanorma
  module Standoc
    class FormInputMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :input

      def process(_parent, target, attr)
        m = %w(id name value disabled readonly checked maxlength minlength)
          .map { |a| attr[a] ? " #{a}='#{attr[a]}'" : nil }.compact
        %{<input type='#{target}' #{m.join}/>}
      end
    end

    class FormLabelMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :label
      parse_content_as :text

      def process(parent, target, attr)
        out = Asciidoctor::Inline.new(parent, :quoted, attr["text"]).convert
        %{<label for="#{target}">#{out}</label>}
      end
    end

    class FormTextareaMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :textarea
      using_format :short

      def process(_parent, _target, attr)
        m = %w(id name rows cols value)
          .map { |a| attr[a] ? " #{a}='#{attr[a]}'" : nil }.compact
        %{<textarea #{m.join}/>}
      end
    end

    class FormSelectMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :select
      using_format :short

      def process(parent, _target, attr)
        m = %w(id name size disabled multiple value)
          .map { |a| attr[a] ? " #{a}='#{attr[a]}'" : nil }.compact
        out = Asciidoctor::Inline.new(parent, :quoted, attr["text"]).convert
        %{<select #{m.join}>#{out}</select>}
      end
    end

    class FormOptionMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :option
      using_format :short

      def process(parent, _target, attr)
        m = %w(disabled value)
          .map { |a| attr[a] ? " #{a}='#{attr[a]}'" : nil }.compact
        out = Asciidoctor::Inline.new(parent, :quoted, attr["text"]).convert
        %{<option #{m.join}">#{out}</option>}
      end
    end
  end
end
