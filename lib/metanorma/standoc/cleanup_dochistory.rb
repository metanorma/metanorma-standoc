module Metanorma
  module Standoc
    module Cleanup
      def bib_relation_insert_pt(xmldoc)
        ins = nil
        %w(relation copyright status abstract script language note version
           edition contributor).each do |x|
          ins = xmldoc.at("//bibdata/#{x}[last()]") and break
        end
        ins
      end

      def ext_dochistory_cleanup(xmldoc)
        t = xmldoc.xpath("//metanorma-extension/clause/title").detect do |x|
          x.text.strip.casecmp("document history").zero?
        end or return
        a = t.at("../sourcecode") or return
        ins = bib_relation_insert_pt(xmldoc) or return
        docid = xmldoc.at("//bibdata/docidentifier")
        yaml = YAML.safe_load(a.text, permitted_classes: [Date])
        ext_dochistory_process(yaml, ins, docid)
      end

      def ext_dochistory_process(yaml, ins, docid)
        yaml.is_a?(Hash) and yaml = [yaml]
        yaml.reverse.each do |y|
          type = y["relation.type"] || "updatedBy"
          docid and
            y["docid"] ||= [{ "type" => "#{docid['type']}___inherited",
                              "id" => docid.text }]
          r = dochistory_yaml2relaton(y, docid,
                                      "#{docid['type']}___inherited")
          ins.next = "<relation type='#{type}'>#{r}</relation>"
        end
      end

      def dochistory_yaml2relaton(yaml, docid, type)
        r = yaml2relaton(yaml, amend_hash2mn(yaml["amend"]))
        docid or return r
        xml = Nokogiri::XML(r)
        xml.xpath("//docidentifier[@type = '#{type}']").each do |d|
          d["type"] = docid["type"]
          docid["boilerplate"] and d["boilerplate"] = docid["boilerplate"]
        end
        to_xml(xml)
      end

      def amend_hash2mn(yaml)
        yaml.nil? and return ""
        yaml.is_a?(Hash) and yaml = [yaml]
        yaml.map { |x| amend_hash2mn1(x) }.join("\n")
      end

      def amend_attrs(yaml)
        ret = ""
        yaml["change"] ||= "modify"
        %w(change path path_end title).each do |x|
          a = yaml[x] and ret += " #{x}='#{a}'"
        end
        ret = "<amend#{ret}>"
      end

      def amend_hash2mn1(yaml)
        ret = amend_attrs(yaml)
        ret += amend_description(yaml)
        ret += amend_location(yaml)
        ret += amend_classification(yaml)
        "#{ret}</amend>"
      end

      def amend_location(yaml)
        a = yaml["location"] or return ""
        a.is_a?(Array) or a = [a]
        ret = a.map do |x|
          elem = Nokogiri::XML("<location>#{x}</location>").root
          extract_localities(elem)
          elem.children.to_xml
        end.join("\n")
        "<location>#{ret}</location>"
      end

      def amend_description(yaml)
        a = yaml["description"] or return ""
        out = adoc2xml(a, backend.to_sym)
        "<description>#{out.children.to_xml}</description>"
      end

      def amend_classification(yaml)
        a = yaml["classification"] or return ""
        a.is_a?(Array) or a = [a]
        a.map { |x| amend_classification1(x) }.join("\n")
      end

      def amend_classification1(yaml)
        yaml.is_a?(Hash) or yaml = { "tag" => "default", "value" => yaml }
        <<~OUT
          <classification><tag>#{yaml['tag']}</tag><value>#{yaml['value']}</value></classification>
        OUT
      end
    end
  end
end
