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

    class TermRefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :term
      name_positional_attributes "name", "termxref"
      using_format :short

      def process(_parent, _target, attrs)
        termref = attrs["termxref"] || attrs["name"]
        "<concept><termxref>#{attrs['name']}</termxref>"\
          "<displayterm>#{termref}</displayterm></concept>"
      end
    end

    # Possibilities:
    # {{<<id>>, term}}
    # {{<<id>>, term, text}}
    # {{termbase:id, term}}
    # {{termbase:id, term, text}}
    # {{term}} equivalent to term:[term]
    # {{text, text}} equivalent to term:[term, text]
    class ConceptInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :concept
      name_positional_attributes "id", "word", "term"
      # match %r{concept:(?<target>[^\[]*)\[(?<content>|.*?[^\\])\]$}
      match /\{\{(?<content>|.*?[^\\])\}\}/
      using_format :short

      # deal with locality attrs and their disruption of positional attrs
      def preprocess_attrs(attrs)
        attrs = preprocess_attrs1(attrs)
        attrs.delete("term") if attrs["term"] && !attrs["word"] && attrs["id"]
        attrs.delete(3) if attrs[3] == attrs["term"]
        a = attrs.keys.reject { |k| k.is_a?(String) || [1, 2].include?(k) }
        attrs["word"] ||= attrs[a[0]] if !a.empty?
        attrs["term"] ||= attrs[a[1]] if a.length > 1
        attrs
      end

      def preprocess_attrs1(attrs)
        if /^&lt;&lt;.+&gt;&gt;$/.match?(attrs["id"])
          attrs["id"] = attrs["id"].sub(/^&lt;&lt;/, "").sub(/&gt;&gt;$/, "")
        elsif !/.:./.match?(attrs["id"])
          attrs["term"] = attrs["id"]
          attrs["word"] ||= attrs["term"]
          attrs.delete("id")
        end
        attrs
      end

      def preprocess_localities(attrs)
        attrs.keys.reject { |k| %w(id word term).include? k }
          .reject { |k| k.is_a? Numeric }
          .map { |k| "#{k}=#{attrs[k]}" }.join(",")
      end

      def process(parent, _target, attrs)
        attrs = preprocess_attrs(attrs)
        loc = preprocess_localities(attrs)
        text = [loc, attrs["word"]].reject { |k| k.nil? || k.empty? }.join(",")
        out = Asciidoctor::Inline.new(parent, :quoted, text).convert
        attrs["id"] and return "<concept key='#{attrs['id']}'><refterm>"\
          "#{attrs['term']}</refterm><displayterm>#{out}</displayterm>"\
          "</concept>"
        "<concept><termxref>#{attrs['term']}</termxref>"\
          "<displayterm>#{attrs['word']}</displayterm></concept>"
      end
    end
  end
end
