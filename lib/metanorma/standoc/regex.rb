module Metanorma
  module Standoc
    module Regex
      # https://medium.com/@rickwang_wxc/in-ruby-given-a-string-detect-if-it-is-valid-numeric-c58275eace60
      NUMERIC_REGEX = %r{\A((\+|-)?\d*\.?\d+)([eE](\+|-){1}\d+)?\Z}

      # extending localities to cover ISO referencing
      CONN_REGEX_STR = "(?<conn>and|or|from|to)(?<custom>:[^!]+)?!".freeze

      LOCALITIES = "section|clause|part|paragraph|chapter|page|line|" \
        "table|annex|figure|example|note|formula|list|time|anchor|" \
        "locality:[^ \\t\\n\\r:,;=]+".freeze

      LOCALITY_REGEX_STR = <<~REGEXP.freeze
        ^((#{CONN_REGEX_STR})?
            (?<locality>#{LOCALITIES})(\\s+|=)
               (?<ref>[^"][^ \\t\\n,:;-]*|"[^"]+")
                 (-(?<to>[^"][^ \\t\\n,:;-]*|"[^"]"))?|
          (?<locality2>whole|title|locality:[^ \\t\\n\\r:,;=]+))(?<punct>[,:;]?)\\s*
         (?<text>.*)$
      REGEXP

      def to_regex(str)
        Regexp.new(str.gsub(/\s/, ""), Regexp::IGNORECASE | Regexp::MULTILINE)
      end

      LOCALITY_REGEX_VALUE_ONLY_STR = <<~REGEXP.freeze
        ^(?<conn0>(#{CONN_REGEX_STR}))
          (?!whole|title|locality:)
          (?<value>[^=,;:\\t\\n\\r]+)
          (?<punct>[,;\\t\\n\\r]|$)
      REGEXP

      LOCALITY_REGEX_STR_TRIPLEDASH = <<~REGEXP.freeze
        ^(?<locality>(#{CONN_REGEX_STR})?
            (#{LOCALITIES})(\\s+|=))
               (?<ref>[^"][^ \\t\\n,:;-]*
                 -[^ \\t\\n,:;"-]+
                 -[^ \\t\\n,:;"]+)
          (?<text>[,:;]?\\s*
         .*)$
      REGEXP

      TERM_REFERENCE_RE_STR = <<~REGEXP.freeze
        ^(?<xref><(xref|concept)[^>]+>(.*?</(xref|concept)>)?)
               (,\s(?<text>.*))?
        $
      REGEXP
      TERM_REFERENCE_RE =
        Regexp.new(TERM_REFERENCE_RE_STR.gsub(/\s/, "").gsub(/_/, "\\s"),
                   Regexp::IGNORECASE | Regexp::MULTILINE)

      ISO_REF =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\(.+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9-]+|IEV)
      (?::(?<year>[0-9][0-9-]+))?\]</ref>,?\s*
        (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?\s*(?<text>.*)$}xm

      ISO_REF_NO_YEAR =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\(.+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9-]+):
      (?:--|–|—|&\#821[12];)\]</ref>,?\s*
        (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?,?\s?(?<text>.*)$}xm

      ISO_REF_ALL_PARTS =
        %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\(.+\))?(?<code>(?:ISO|IEC)[^0-9]*\s[0-9]+)
      (?::(?<year>--|–|—|&\#821[12];|[0-9][0-9-]+))?\s
      \(all\sparts\)\]</ref>,?\s*
        (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>,?\s?)?(?<text>.*)$}xm

      # These regexes allow () inside usrlbl but not inside code
      NON_ISO_REF = %r{^<ref\sid="(?<anchor>[^"]+)">
      \[(?<usrlbl>\(.+\))?(?<code>.+)\]</ref>,?\s*
      (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>)?(?<text>.*)$}xm

      NON_ISO_REF1 = %r{^<ref\sid="(?<anchor>[^"]+)">
      (?<usrlbl>\(.+\))?(?<code>.+)</ref>,?\s*
      (?:<fn[^>]*>\s*<p>(?<fn>[^\]]+)</p>\s*</fn>\s*)?(?<text>.*)$}xm
    end
  end
end
