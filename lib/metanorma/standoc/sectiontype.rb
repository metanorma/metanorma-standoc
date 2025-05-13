module Metanorma
  module Standoc
    module Section
      def sectiontype1(node)
        node.attr("style") == "abstract" and return "abstract"
        node.attr("heading")&.downcase ||
          node.title
            .gsub(%r{<index>.*?</index>}m, "")
            .gsub(%r{<fn[^<>]*>.*?</fn>}m, "")
            .gsub(/<[^<>]+>/, "")
            .strip.downcase.sub(/\.$/, "")
      end

      def sectiontype(node, level = true)
        ret = sectiontype1(node)
        ret1 = preface_main_filter(sectiontype_streamline(ret), node)
        # permit multiple instances
        ["symbols and abbreviated terms",
         "metanorma-extension"].include?(ret1) and return ret1
        !level || node.level == 1 || node.attr("heading") or return nil
        !node.attr("heading") && @seen_headers.include?(ret) and return nil
        @seen_headers << ret unless ret1.nil?
        @seen_headers_canonical << ret1 unless ret1.nil?
        ret1
      end

      SECTIONTYPE_STREAMLINE =
        { "terms and definitions":
          ["terms, definitions, symbols and abbreviated terms",
           "terms, definitions, symbols and abbreviations",
           "terms, definitions and symbols",
           "terms, definitions and abbreviations",
           "terms, definitions and abbreviated terms",
           "terms and definitions"],
          "symbols and abbreviated terms":
        ["symbols and abbreviated terms",
         "symbols", "abbreviated terms", "abbreviations",
         "symbols and abbreviations",
         "symbols and abbreviated terms"],
          "acknowledgements":
        ["acknowledgements", "acknowledgments"],
          "executivesummary":
          ["executive summary", "executive-summary",
           "executive_summary"],
          "metanorma-extension":
       ["misc-container", "metanorma-extension"] }.freeze

      def sectiontype_streamline(ret)
        SECTIONTYPE_STREAMLINE.each do |k, v|
          v.include?(ret) and return k.to_s
        end
        ret
      end

      PREFACE_CLAUSE_NAMES =
        %w(abstract foreword introduction metanorma-extension termdocsource
           metanorma-extension acknowledgements executivesummary)
          .freeze

      MAIN_CLAUSE_NAMES =
        ["normative references", "terms and definitions", "scope",
         "symbols and abbreviated terms", "clause", "bibliography"].freeze

      def role_style(node, value)
        node.role == value || node.attr("style") == value
      end

      def start_main_section(ret, node)
        role_style(node, "preface") and return
        @preface = false if self.class::MAIN_CLAUSE_NAMES.include?(ret)
        @preface = false if self.class::PREFACE_CLAUSE_NAMES
          .intersection(@seen_headers_canonical + [ret]).empty?
      end

      def preface_main_filter(ret, node)
        start_main_section(ret, node)
        @preface && self.class::MAIN_CLAUSE_NAMES.include?(ret) and return nil
        !@preface && self.class::PREFACE_CLAUSE_NAMES.include?(ret) and
          return nil
        ret
      end
    end
  end
end
