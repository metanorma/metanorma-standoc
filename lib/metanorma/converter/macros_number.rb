module Metanorma
  module Standoc
    class NumberInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      include ::Metanorma::Standoc::Utils

      use_dsl
      named :number
      parse_content_as :text

      MATHML_NS = "http://www.w3.org/1998/Math/MathML".freeze

      def unquote(str)
        str.sub(/^(["'])(.+)\1$/, "\\2")
      end

      def format(attrs, number)
        # a="," => "a=,"
        out = quoted_csv_split(attrs || "", ",").map do |x|
          m = /^(.+?)=(.+)?$/.match(HTMLEntities.new.decode(x)) or next
          "#{m[1]}='#{m[2]}'"
        end
        /^\+/.match?(number.strip) and out << "number_sign='plus'"
        out.join(",")
      end

      # Handle numbers with fractional parts in different bases
      # Split on decimal point
      def parse_number_with_base(num_str, base)
        integer_part, fractional_part = split_number(num_str)
        int_value = integer_part.to_i(base)
        frac_value = 0.0
        fractional_part.chars.each_with_index do |digit, index|
          digit_val = digit.to_i(base)
          frac_value += digit_val * (base**-(index + 1))
        end
        (int_value + frac_value).to_s
      end

      def split_number(num_str)
        parts = num_str.split(".")
        integer_part = parts[0] || "0"
        fractional_part = parts[1] || ""
        [integer_part, fractional_part]
      end

      # The value emitted into <mn> is canonical positional decimal:
      # the exponent form is a rendering decision driven by the
      # number-format attributes, not baked into the semantic content.
      def number(text)
        case text.strip
        when /^0[xX]([0-9A-Fa-f.]+)$/
          parse_number_with_base(Regexp.last_match(1), 16)
        when /^0[bB]([01.]+)$/
          parse_number_with_base(Regexp.last_match(1), 2)
        when /^0[oO]([0-7.]+)$/
          parse_number_with_base(Regexp.last_match(1), 8)
        when /\A[0-9]+(\.[0-9]+)?[eE][+-]?[0-9]+\z/
          BigDecimal(text.strip).to_s("F").sub(/\.0\z/, "")
        when /\A[0-9]+(\.[0-9]+)?\z/
          text.strip # Regular decimal - pass through
        else
          BigDecimal(text.strip).to_s("F").sub(/\.0\z/, "")
        end
      end

      # Handle numbers with fractional parts in different bases
      # Split on decimal point
      def parse_number_with_base(num_str, base)
        integer_part, fractional_part = split_number(num_str)
        int_value = integer_part.to_i(base)
        return int_value.to_s if fractional_part.empty?
        frac_value = fractional_part.chars.each_with_index.sum do |digit, index|
          BigDecimal(digit.to_i(base).to_s) / BigDecimal((base**(index + 1)).to_s)
        end
        (BigDecimal(int_value.to_s) + frac_value).to_s("F")
      end

      def process(parent, target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        fmt = format(out, target)
        fmt.empty? and fmt = "default"
        fmt = %( number-format="#{fmt}")
        "<mathml-number#{fmt}>#{number(target)}</mathml-number>"
      end
    end
  end
end
