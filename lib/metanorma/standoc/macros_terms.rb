require "csv"

module Asciidoctor
  module Standoc
    class PreferredTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :preferred
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<preferred><expression><name>#{out}</name></expression></preferred>}
      end
    end

    class AltTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :alt
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted,
                                      attrs["text"]).convert
        %{<admitted><expression><name>#{out}</name></expression></admitted>}
      end
    end

    class DeprecatedTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :deprecated
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted,
                                      attrs["text"]).convert
        %{<deprecates><expression><name>#{out}</name></expression></deprecates>}
      end
    end

    class DomainTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :domain
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted,
                                      attrs["text"]).convert
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
        if m2 = /^(?<rest>.*?)(?<opt>,opt(ion)?s=.+)$/
            .match(m[:rest].sub(/^,/, ""))
          ret[:opt] = CSV.parse_line(m2[:opt].sub(/^,opt(ion)?s=/, "")
            .sub(/^"(.+)"$/, "\\1").sub(/^'(.+)'$/, "\\1"))
          begin
            attrs = CSV.parse_line(m2[:rest]) || []
          rescue StandardError
            raise "error processing #{m2[:rest]} as CSV"
          end
        else
          begin
            attrs = CSV.parse_line(m[:rest].sub(/^,/, "")) || []
          rescue StandardError
            raise "error processing #{m[:rest]} as CSV"
          end
        end
        ret.merge(term: attrs[0], word: attrs[1] || attrs[0],
                  render: attrs[2])
      end

      def generate_attrs(opts)
        ret = ""
        opts.include?("noital") and ret += " ital='false'"
        opts.include?("noref") and ret += " ref='false'"
        opts.include?("ital") and ret += " ital='true'"
        opts.include?("ref") and ret += " ref='true'"
        opts.include?("nolinkmention") and ret += " linkmention='false'"
        opts.include?("linkmention") and ret += " linkmention='true'"
        opts.include?("nolinkref") and ret += " linkref='false'"
        opts.include?("linkref") and ret += " linkref='true'"
        ret
      end

      def process(parent, target, _attrs)
        attrs = preprocess_attrs(target)
        term = Asciidoctor::Inline.new(parent, :quoted,
                                       attrs[:term]).convert
        word = Asciidoctor::Inline.new(parent, :quoted,
                                       attrs[:word]).convert
        xref = Asciidoctor::Inline.new(parent, :quoted,
                                       attrs[:render]).convert
        opt = generate_attrs(attrs[:opt] || [])
        if attrs[:id] then "<concept#{opt} key='#{attrs[:id]}'><refterm>"\
          "#{term}</refterm><renderterm>#{word}</renderterm>"\
          "<xrefrender>#{xref}</xrefrender></concept>"
        else "<concept#{opt}><termxref>#{term}</termxref><renderterm>"\
          "#{word}</renderterm><xrefrender>#{xref}</xrefrender></concept>"
        end
      rescue StandardError => e
        raise("processing {{#{target}}}: #{e.message}")
      end
    end

    # Possibilities:
    # related:relation[<<id>>, term]
    # related:relation[<<termbase:id>>, term]
    # related:relation[term] equivalent to a crossreference to term:[term]
    class RelatedTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :related
      parse_content_as :text

      def preprocess_attrs(target)
        m = /^(?<id>&lt;&lt;.+?&gt;&gt;, ?)?(?<rest>.*)$/.match(target)
        { id: m[:id]&.sub(/^&lt;&lt;/, "")&.sub(/&gt;&gt;, ?$/, ""),
          term: m[:rest] }
      end

      def process(parent, target, attrs)
        out = preprocess_attrs(attrs["text"])
        term = Asciidoctor::Inline.new(parent, :quoted,
                                       out[:term]).convert
        if out[:id] then "<related type='#{target}' key='#{out[:id]}'>"\
          "<refterm>#{term}</refterm></related>"
        else "<related type='#{target}'><termxref>#{term}</termxref>"\
          "<xrefrender>#{term}</xrefrender></related>"
        end
      rescue StandardError => e
        raise("processing related:#{target}[#{attrs['text']}]: #{e.message}")
      end
    end
  end
end
