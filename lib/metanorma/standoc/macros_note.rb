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

          parent = para.parent
          para.set_attr("name", "todo")
          para.set_attr("caption", "TODO")
          para.lines[0].sub!(/^TODO: /, "")
          todo = Asciidoctor::Block.new(parent, :admonition, attributes: para.attributes,
                                                             source: para.lines,
                                                             content_model: :compound)
          parent.blocks[parent.blocks.index(para)] = todo
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
  end
end
