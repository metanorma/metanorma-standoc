require "csv"

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
        "<concept type='term'><termxref>#{attrs['name']}</termxref>"\
          "<renderterm>#{termref}</renderterm><xrefrender/></concept>"
      end
    end

    class SymbolRefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :symbol
      name_positional_attributes "name", "termxref"
      using_format :short

      def process(_parent, _target, attrs)
        termref = attrs["termxref"] || attrs["name"]
        "<concept type='symbol'><termxref>#{attrs['name']}</termxref>"\
          "<renderterm>#{termref}</renderterm><xrefrender/></concept>"
      end
    end

    # Possibilities:
    # {{<<id>>, term}}
    # {{<<id>>, term, text}}
    # {{<<termbase:id>>, term}}
    # {{<<termbase:id>>, term, text}}
    # {{term}} equivalent to term:[term]
    # {{term, text}} equivalent to term:[term, text]
    # text may optionally be followed by crossreference-rendering, options=""
    class ConceptInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :concept
      match /\{\{(?<content>|.*?[^\\])\}\}/
      using_format :short

      def preprocess_attrs(target)
        m = /^(?<id>&lt;&lt;.+?&gt;&gt;)?(?<rest>.*)$/.match(target)
        ret = { id: m[:id]&.sub(/^&lt;&lt;/, "")&.sub(/&gt;&gt;$/, "") }
        if m2 = /^(?<rest>.*?)(?<opt>,option=.+)$/.match(m[:rest].sub(/^,/, ""))
          ret[:opt] = CSV.parse_line(m2[:opt].sub(/^,option=/, "")
            .sub(/^"(.+)"$/, "\\1").sub(/^'(.+)'$/, "\\1"))
          attrs = CSV.parse_line(m2[:rest]) || []
        else
          attrs = CSV.parse_line(m[:rest].sub(/^,/, "")) || []
        end
        ret.merge(term: attrs[0], word: attrs[1] || attrs[0],
                  xrefrender: attrs[2])
      end

      def generate_attrs(opts)
        ret = ""
        opts.include?("noital") and ret += " noital='true'"
        opts.include?("noref") and ret += " noref='true'"
        ret
      end

      def process(parent, target, _attrs)
        attrs = preprocess_attrs(target)
        termout = Asciidoctor::Inline.new(parent, :quoted, attrs[:term]).convert
        wordout = Asciidoctor::Inline.new(parent, :quoted, attrs[:word]).convert
        xrefout = Asciidoctor::Inline.new(parent, :quoted,
                                          attrs[:xrefrender]).convert
        optout = generate_attrs(attrs[:opt] || [])
        attrs[:id] and return "<concept#{optout} key='#{attrs[:id]}'><refterm>"\
          "#{termout}</refterm><renderterm>#{wordout}</renderterm>"\
          "<xrefrender>#{xrefout}</xrefrender></concept>"
        "<concept#{optout}><termxref>#{termout}</termxref><renderterm>"\
          "#{wordout}</renderterm><xrefrender>#{xrefout}</xrefrender></concept>"
      end
    end
  end
end
