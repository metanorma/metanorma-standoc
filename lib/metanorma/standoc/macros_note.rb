module Metanorma
  module Standoc
    class ToDoAdmonitionBlock < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :TODO
      on_contexts :example, :paragraph

      def process(parent, reader, attrs)
        attrs["name"] = "todo"
        attrs["caption"] = "TODO"
        create_block(parent, :admonition, reader.lines, attrs,
                     content_model: :compound)
      end
    end

    class ToDoInlineAdmonitionBlock < Asciidoctor::Extensions::Treeprocessor
      def process(document)
        (document.find_by context: :paragraph).each do |para|
          next unless /^TODO: /.match? para.lines[0]

          para.set_attr("name", "todo")
          para.set_attr("caption", "TODO")
          para.lines[0].sub!(/^TODO: /, "")
          para.context = :admonition
        end
      end
    end

    class FootnoteBlockInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :footnoteblock
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<footnoteblock>#{out}</footnoteblock>}
      end
    end

    class EditorAdmonitionBlock < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :EDITOR
      on_contexts :example, :paragraph

      def process(parent, reader, attrs)
        require "debug"; binding.b
        attrs["name"] = "editorial"
        attrs["caption"] = "EDITOR"
        create_block(parent, :admonition, reader.lines, attrs,
                     content_model: :compound)
      end
    end

    class EditorInlineAdmonitionBlock < Asciidoctor::Extensions::Treeprocessor
      def process(document)
        (document.find_by context: :paragraph).each do |para|
          next unless /^EDITOR: /.match? para.lines[0]

          para.set_attr("name", "editorial")
          para.set_attr("caption", "EDITOR")
          para.lines[0].sub!(/^EDITOR: /, "")
          para.context = :admonition
        end
      end
    end
  end
end
