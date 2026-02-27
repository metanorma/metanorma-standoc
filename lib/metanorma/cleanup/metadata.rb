module Metanorma
  module Standoc
    module Metadata
      def metadata_cleanup(xmldoc)
        bibdata_published(xmldoc) # feeds: bibdata_cleanup,
        # docidentifier_cleanup (in generic: template)
        metadata_attrs = @conv.instance_variable_get(:@metadata_attrs)
        (metadata_attrs.nil? || metadata_attrs.empty?) and return
        ins = add_misc_container(xmldoc)
        ins << metadata_attrs
      end

      def pres_metadata_cleanup(xmldoc)
        unless @isodoc
          @isodoc = @conv.isodoc(@lang, @script, @locale)
          @conv.instance_variable_set(:@isodoc, @isodoc)
        end
        isodoc_bibdata_parse(xmldoc)
        xmldoc.xpath("//presentation-metadata/* | //semantic-metadata/*")
          .each do |x|
          /\{\{|\{%/.match?(x) or next
          x.children = @isodoc.populate_template(
            to_xml(x.children), nil
          )
        end
      end

      def metadata_cleanup_final(xmldoc)
        root = nil
        %w(semantic presentation).each do |k|
          xmldoc.xpath("//#{k}-metadata").each_with_index do |x, i|
            if i.zero? then root = x
            else
              root << x.remove.elements
            end
          end
        end
      end

      def annotation_cleanup(xmldoc)
        ret = xmldoc.xpath("//annotation[@type = 'ignore-log']")
          .each_with_object([]) do |ann, m|
          error_ids = Array(@conv.csv_split(ann.text || "", ","))
          m << { from: ann["from"], to: ann["to"],
                 error_ids: error_ids }
          ann
        end
        config = @log.suppress_log
        config[:locations] += ret
        @log.suppress_log = config
      end
    end
  end
end
