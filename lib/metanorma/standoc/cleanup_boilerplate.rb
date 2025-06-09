require_relative "cleanup_terms_boilerplate"

module Metanorma
  module Standoc
    module Cleanup
      def norm_ref_preface(ref)
        ins = norm_ref_boilerplate_insert_location(ref)
        ins2 = norm_ref_process_boilerplate_note(ref)
        ins2 == :populated and return
        ins2 == :missing or ins = ins2
        refs = ref.elements.select do |e|
          %w(references bibitem).include? e.name
        end
        pref = refs.empty? ? @i18n.norm_empty_pref : @i18n.norm_with_refs_pref
        ins.next = boilerplate_snippet_convert(pref)
      end

      def norm_ref_process_boilerplate_note(ref)
        ins2 = ref.at("./note[@type = 'boilerplate']") or return :missing
        if ins2 && ins2.text.strip.downcase == "(default)"
          ins2.children = " "
          ins2.children.first
        else :populated
        end
      end

      def norm_ref_boilerplate_insert_location(ref)
        while (n = ref.parent) && %w(clause references).include?(n.name)
          n.elements.detect do |e|
            !%(title references).include?(e.name) &&
              !e.at("./self::clause[@type = 'boilerplate']") &&
              !e.at("./self::clause[.//references][not(.//clause[not(.//bibitem)])]")
          end and break
          ref = n
        end
        ref.at("./title")
      end

      NORM_REF =
        "//bibliography/references[@normative = 'true'][not(@hidden)] | " \
        "//bibliography/clause[.//references[@normative = 'true']]".freeze

      def boilerplate_isodoc(xmldoc)
        # prevent infinite recursion of asciidoc boilerplate processing
        # in termdef_boilerplate_insert and initial_boilerplate
        xmldoc.at("//metanorma-extension/semantic-metadata/" \
                  "headless[text() = 'true']") and return nil
        x = xmldoc.dup
        x.root.add_namespace(nil, xml_namespace)
        xml = Nokogiri::XML(x.to_xml)
        @isodoc ||= isodoc(@lang, @script, @locale)
        @isodoc.info(xml, nil)
        @isodoc
      end

      def unwrap_boilerplate_clauses(xmldoc, xpath)
        xmldoc.xpath(xpath).each do |f|
          f.xpath(".//clause[@type = 'boilerplate'] | " \
                  ".//note[@type = 'boilerplate']").each do |c|
            c.at("./title")&.remove
            c.replace(c.children)
          end
        end
      end

      def boilerplate_cleanup(xmldoc)
        isodoc = boilerplate_isodoc(xmldoc) or return
        # boilerplate_isodoc_values(isodoc)
        termdef_boilerplate_cleanup(xmldoc)
        termdef_boilerplate_insert(xmldoc, isodoc)
        unwrap_boilerplate_clauses(xmldoc, self.class::TERM_CLAUSE)
        if f = xmldoc.at(self.class::NORM_REF)
          norm_ref_preface(f)
          unwrap_boilerplate_clauses(f, ".")
        end
        initial_boilerplate(xmldoc, isodoc)
      end

      # KILL
      # escape &lt; &gt; &amp; to &amp;gt; etc,
      # for passthrough insertion into boilerplate
      def boilerplate_isodoc_values(isodoc)
        isodoc.meta.get.each do |k, v|
          if v.is_a?(String)
            isodoc.meta.set(k, v.gsub("&amp;", "&&&&&&&")
              .gsub("&lt;", "&amp;lt;").gsub("&gt;", "&amp;gt;")
              .gsub("&&&&&&&", "&amp;amp;"))
          end
        end
      end

      def initial_boilerplate(xml, isodoc)
        xml.at("//boilerplate") and return
        preface = xml.at("//preface | //sections | //annex | //references") or
          return
        b = boilerplate(xml, isodoc) or return
        preface.previous = b
      end

      def boilerplate_file(_xmldoc)
        ret = File.join(@libdir, "boilerplate.xml")
        File.exist?(ret) ? ret : ""
      end

      def boilerplate(xml, conv)
        # prevent infinite recursion of asciidoc boilerplate processing
        xml.at("//metanorma-extension/semantic-metadata/" \
               "headless[text() = 'true']") and return nil
        file = boilerplate_file(xml)
        file2 = @boilerplateauthority
        @boilerplateauthority &&
          !(Pathname.new @boilerplateauthority).absolute? and
          file2 = File.join(@localdir, @boilerplateauthority)
        resolve_boilerplate_files(process_boilerplate_file(file, conv),
                                  process_boilerplate_file(file2, conv))
      end

      def process_boilerplate_file(filename, conv)
        filename.nil? || filename.empty? and return
        filename = filename.strip
        unless File.exist?(filename)
          msg = "Specified boilerplate file does not exist: #{filename}"
          @log.add("Include", nil, msg, severity: 0)
          return
        end

        b = conv.populate_template(boilerplate_read(filename), nil)
          .gsub(/pass-format:metanorma\[\+\+\+\+\]\s*/, "")
        boilerplate_file_convert(b)
      end

      def resolve_boilerplate_files(built_in, user_add)
        built_in || user_add or return
        built_in && user_add or return to_xml(built_in || user_add)
        merge_boilerplate_files(built_in, user_add)
      end

      def merge_boilerplate_files(built_in, user_add)
        %w(copyright license legal feedback).each do |w|
          resolve_boilerplate_statement(built_in, user_add, w)
          resolve_boilerplate_append(built_in, user_add, w)
        end
        to_xml(built_in)
      end

      def resolve_boilerplate_statement(built_in, user_add, statement)
        b = user_add.at("./#{statement}-statement") or return
        if a = built_in.at("./#{statement}-statement")
          b.text.strip.empty? and a.remove or a.replace(b)
        else
          built_in << b
        end
      end

      def resolve_boilerplate_append(built_in, user_add, statement)
        b = user_add.at("./#{statement}-statement-append") or return
        if a = built_in.at("./#{statement}-statement")
          resolve_boilerplate_append1(a, b, statement)
        else
          b.name = "#{statement}-statement"
          built_in << b
        end
      end

      def resolve_boilerplate_append1(built_in, user_add, statement)
        if user_add.at("./clause") then built_in << user_add.children
        else
          user_add.name = "clause"
          if user_add["id"].nil? || uuid?(user_add["id"])
            user_add["anchor"] = "_boilerplate-#{statement}-statement-append"
            add_id(user_add)
          end
          built_in << user_add
        end
      end

      # Asciidoc macro, e.g. span:publisher[...]
      # May contain one or more {{ }} in target, with spaces in them
      # Does not end in \]
      ADOC_MACRO_START = '\S+:(?:[^\[\] ]+|\{\{[^{}]+\}\})*\[.*?(?<!\\\\)\]'.freeze

      # Replace {{ ... }} with {{ pass:[...]}} to preserve any XML markup
      # use pass:[...\] if {{}} is already inside an Asciidoc macro
      # Do not use pass: if this is a macro target: mailto:{{x}}[] 
      # or body: mailto:[{{x}}]
      def boilerplate_read(file)
        ret = File.read(file, encoding: "UTF-8")
        /\.adoc$/.match?(file) or return ret
        ret.split(/(#{ADOC_MACRO_START}|\])/o).map do |r|
          if /^#{ADOC_MACRO_START}$/o.match?(r)
            r
          else
            r.gsub(/(?<!\{)(\{\{[^{}]+\}\})(?!\})/,
                   "pass-format:metanorma[++\\1++]")
          end
        end.join
      end

      # If Asciidoctor, convert top clauses to tags and wrap in <boilerplate>
      def boilerplate_file_convert(file)
        ret = Nokogiri::XML(file).root and return ret
        boilerplate_file_restructure(file)
      end

      def boilerplate_file_restructure(file)
        ret = adoc2xml(file, backend.to_sym)
        boilerplate_xml_cleanup(ret)
        ret.name = "boilerplate"
        boilerplate_top_elements(ret)
        ret
      end

      # remove Metanorma namespace, so generated doc containing boilerplate
      # can be queried consistently
      # _\d+ anchor is assigned to titleless clauses, will clash with main doc
      # instances of same
      def boilerplate_xml_cleanup(xml)
        ns = xml.namespace.href
        xml.traverse do |n|
          n.element? or next
          n.namespace.href == ns and n.namespace = nil
          /^_\d+$/.match?(n["id"]) and add_id(n)
        end
        xml
      end

      def boilerplate_top_elements(xml)
        xml.elements.each do |e|
          (t = e.at("./title") and
           /-statement(-append)?$/.match?(t.text)) or next
          e.name = t.remove.text
          e.keys.each { |a| e.delete(a) } # rubocop:disable Style/HashEachMethods
        end
      end
    end
  end
end
