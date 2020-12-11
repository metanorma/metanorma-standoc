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

     # Macro to transform `term[X,Y]` into em, termxref xml
    class TermRefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :term
      name_positional_attributes 'name', 'termxref'
      using_format :short

      def process(_parent, _target, attrs)
        termref = attrs['termxref'] || attrs['name']
        "<em>#{attrs['name']}</em> (<termxref>#{termref}</termxref>)"
      end
    end

    class ConceptInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :concept
      name_positional_attributes "id", "word", "term"
      # match %r{concept:(?<target>[^\[]*)\[(?<content>|.*?[^\\])\]$}
      match /\{\{(?<content>|.*?[^\\])\}\}/
      using_format :short

      # deal with locality attrs and their disruption of positional attrs
      def preprocess_attrs(attrs)
        attrs.delete("term") if attrs["term"] && !attrs["word"]
        attrs.delete(3) if attrs[3] == attrs["term"]
        a = attrs.keys.reject { |k| k.is_a?(String) || [1, 2].include?(k) }
        attrs["word"] ||= attrs[a[0]] if !a.empty?
        attrs["term"] ||= attrs[a[1]] if a.length > 1
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
  end
end
