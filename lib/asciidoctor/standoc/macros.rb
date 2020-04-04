require "asciidoctor/extensions"
require "fileutils"
require "uuidtools"
require_relative "./macros_plantuml.rb"

module Asciidoctor
  module Standoc
    class AltTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :alt
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<admitted>#{out}</admitted>}
      end
    end

    class DeprecatedTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :deprecated
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<deprecates>#{out}</deprecates>}
      end
    end

    class DomainTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :domain
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<domain>#{out}</domain>}
      end
    end

    class InheritInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :inherit
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<inherit>#{out}</inherit>}
      end
    end

    class ConceptInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :concept
      name_positional_attributes "id", "word", "term"
      #match %r{concept:(?<target>[^\[]*)\[(?<content>|.*?[^\\])\]$}
      match /\{\{(?<content>|.*?[^\\])\}\}$/
      using_format :short

      # deal with locality attrs and their disruption of positional attrs
      def preprocess_attrs(attrs)
        attrs.delete("term") if attrs["term"] and !attrs["word"]
        attrs.delete(3) if attrs[3] == attrs["term"]
        a = attrs.keys.reject { |k| k.is_a? String or [1, 2].include? k }
        attrs["word"] ||= attrs[a[0]] if a.length() > 0
        attrs["term"] ||= attrs[a[1]] if a.length() > 1
        attrs
      end

      def process(parent, _target, attr)
        attr = preprocess_attrs(attr)
        localities = attr.keys.reject { |k| %w(id word term).include? k }.
          reject { |k| k.is_a? Numeric }.
          map { |k| "#{k}=#{attr[k]}" }.join(",")
        text = [localities, attr["word"]].reject{ |k| k.nil? || k.empty? }.
          join(",")
        out = Asciidoctor::Inline.new(parent, :quoted, text).convert
        %{<concept key="#{attr['id']}" term="#{attr['term']}">#{out}</concept>}
      end
    end

    class PseudocodeBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :pseudocode
      on_context :example, :sourcecode

      def init_indent(s)
        /^(?<prefix>[ \t]*)(?<suffix>.*)$/ =~ s
        prefix = prefix.gsub(/\t/, "\u00a0\u00a0\u00a0\u00a0").
          gsub(/ /, "\u00a0")
        prefix + suffix
      end

      def supply_br(lines)
        lines.each_with_index do |l, i|
          next if l.empty? || l.match(/ \+$/)
          next if i == lines.size - 1 || i < lines.size - 1 && lines[i+1].empty?
          lines[i] += " +"
        end
        lines
      end

      def prevent_smart_quotes(m)
        m.gsub(/'/, "&#x27;").gsub(/"/, "&#x22;")
      end

      def process parent, reader, attrs
        attrs['role'] = 'pseudocode'
        lines = reader.lines.map { |m| prevent_smart_quotes(init_indent(m)) }
        create_block(parent, :example, supply_br(lines),
                     attrs, content_model: :compound)
      end
    end

    class HTML5RubyMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :ruby
      parse_content_as :text
      option :pos_attrs, %w(rpbegin rt rpend)

      def process(parent, target, attributes)
        rpbegin = '('
        rpend = ')'
        if attributes.size == 1 and attributes.key?("text")
          rt = attributes["text"]
        elsif attributes.size == 2 and attributes.key?(1) and
          attributes.key?("rpbegin")
          # for example, html5ruby:楽聖少女[がくせいしょうじょ]
          rt = attributes[1] || ""
        else
          rpbegin = attributes['rpbegin']
          rt = attributes['rt']
          rpend = attributes['rpend']
        end

        "<ruby>#{target}<rp>#{rpbegin}</rp><rt>#{rt}</rt>"\
          "<rp>#{rpend}</rp></ruby>"
      end
    end

    class ToDoAdmonitionBlock < Extensions::BlockProcessor
      use_dsl
      named :TODO
      on_contexts :example, :paragraph

      def process parent, reader, attrs
        attrs['name'] = 'todo'
        attrs['caption'] = 'TODO'
        create_block parent, :admonition, reader.lines, attrs,
          content_model: :compound
      end
    end

    class ToDoInlineAdmonitionBlock < Extensions::Treeprocessor
      def process document
        (document.find_by context: :paragraph).each do |para|
          next unless /^TODO: /.match para.lines[0]
          parent = para.parent
          para.set_attr("name", "todo")
          para.set_attr("caption", "TODO")
          para.lines[0].sub!(/^TODO: /, "")
          todo = Block.new parent, :admonition, attributes: para.attributes,
            source: para.lines, content_model: :compound
          parent.blocks[parent.blocks.index(para)] = todo
        end
      end
    end

    class Yaml2TextPreprocessor < Asciidoctor::Extensions::Preprocessor
      BLOCK_IDENTIFIER = '----'.freeze
      # serch document for block `yaml2text`
      #   after that take template from block and read file into this template
      #   example:
      #     [yaml2text,foobar.yaml]
      #     ----
      #     === {item.name}
      #     {item.desc}
      #
      #     {item.symbol}:: {item.symbol_def}
      #     ----
      #
      #   with content of `foobar.yaml` file equal to:
      #     - name: spaghetti
      #       desc: wheat noodles of 9mm diameter
      #       symbol: SPAG
      #       symbol: the situation is message like spaghetti at a kid's meal
      #
      #   will produce:
      #     === spaghetti
      #     wheat noodles of 9mm diameter
      #
      #     SPAG:: the situation is message like spaghetti at a kid's meal
      def process(document, reader)
        input_lines = reader.readlines
        processed_lines = []
        current_yaml_block = []
        in_yaml_2_text_block = false
        open_block_mark = false
        doc_attrs = document.attributes
        current_yaml_file = nil
        current_yaml_context = nil

        input_lines.each do |line|
          yaml_block_match = line.match(/^\[yaml2text,(.+?),(.+?)\]/)
          if yaml_block_match
            in_yaml_2_text_block = true
            current_yaml_context = yaml_block_match[2]
            current_yaml_file = YAML.load(File.read(yaml_block_match[1]))
            next
          end

          if in_yaml_2_text_block && line.strip == BLOCK_IDENTIFIER
            if open_block_mark && current_yaml_block.length > 0
              result = current_yaml_file.map.with_index do |item,i|
                         item.each_pair do |attr_name, attr_value|
                           doc_attrs["#{current_yaml_context}.#{attr_name}.#{i}"] = attr_value
                         end
                         current_yaml_block.map do |template_line|
                           item.keys.each do |attr_name|
                             template_line.gsub!(/{#{current_yaml_context}.#{attr_name}}/, "#{current_yaml_context}.#{attr_name}.#{i}")
                           end
                           template_line
                         end
                       end.flatten
              processed_lines.push(*result)
              current_yaml_block = []
              in_yaml_2_text_block = false
              open_block_mark = false
              next
            end

            open_block_mark = true
            next
          end

          if in_yaml_2_text_block && line.strip != BLOCK_IDENTIFIER
            current_yaml_block << line
            next
          end

          processed_lines.push(line)
        end
        Reader.new(processed_lines)
      end
    end
  end
end
