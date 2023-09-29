module Metanorma
  module Standoc
    module Refs
      def set_date_range(date, text)
        matched = /^(?<from>[0-9]+)(?:-+(?<to>[0-9]+))?$/.match text
        return unless matched[:from]

        if matched[:to]
          date.from matched[:from]
          date.to matched[:to]
        else
          date.on matched[:from]
        end
      end

      def id_and_year(id, year)
        year ? "#{id}:#{year}" : id
      end

      def norm_year(year)
        /^&\#821[12];$/.match(year) and return "--"
        /^\d\d\d\d-\d\d\d\d$/.match(year) and return year
        year&.sub(/(?<=[0-9])-.*$/, "")
      end

      def conditional_date(bib, match, noyr)
        if match.names.include?("year") && !match[:year].nil?
          bib.date(type: "published") do |d|
            (noyr and d.on "--") or set_date_range(d, norm_year(match[:year]))
          end
        end
      end

      def use_my_anchor(ref, id, opt)
        ref.parent.elements.last["id"] = id
        opt[:hidden] and ref.parent.elements.last["hidden"] = opt[:hidden]
        opt[:dropid] and
          ref.parent.elements.last["suppress_identifier"] = opt[:dropid]
        ref
      end

      def docid(bib, code)
        type, code1 = if /^\[\d+\]$|^\([^)]+\).*$/.match?(code)
                        ["metanorma", mn_code(code)]
                      else
                        @bibdb&.docid_type(code) || [nil, code]
                      end
        code1.sub!(/^nofetch\((.+)\)$/, "\\1")
        bib.docidentifier **attr_code(type: type) do |d|
          d << code1
        end
      end

      def docnumber(bib, code)
        code or return
        bib.docnumber do |d|
          d << @c.decode(code).sub(/^[^\d]*/, "")
        end
      end

      def mn_code(code)
        code.sub(/^\(/, "[").sub(/\).*$/, "]")
          .sub(/^dropid\((.+)\)$/, "\\1")
          .sub(/^hidden\((.+)\)$/, "\\1")
          .sub(/^nofetch\((.+)\)$/, "\\1")
          .sub(/^local-file\((.+)\)$/, "\\1")
      end

      def analyse_ref_localfile(ret)
        m = /^local-file\((?:(?<source>[^,]+),\s*)?(?<id>.+)\)$/.match(ret[:id])
        m or return ret
        ret.merge(id: m[:id], localfile: (m[:source] || "default"))
      end

      def analyse_ref_nofetch(ret)
        m = /^nofetch\((?<id>.+)\)$/.match(ret[:id]) or return ret
        ret.merge(id: m[:id], nofetch: true)
      end

      def analyse_ref_hidden(ret)
        m = /^hidden\((?<id>.+)\)$/.match(ret[:id]) or return ret
        ret.merge(id: m[:id], hidden: true)
      end

      def analyse_ref_dropid(ret)
        m = /^dropid\((?<id>.+)\)$/.match(ret[:id]) or return ret
        ret.merge(id: m[:id], dropid: true)
      end

      def analyse_ref_repo_path(ret)
        m = /^(?<type>repo|path):\((?<key>[^,]+),?(?<id>.*)\)$/
          .match(ret[:id]) or return ret
        id = m[:id].empty? ? m[:key].sub(%r{^[^/]+/}, "") : m[:id]
        ret.merge(id: id, type: m[:type], key: m[:key], nofetch: true)
      end

      def analyse_ref_numeric(ret)
        /^\d+$/.match?(ret[:id]) or return ret
        ret.merge(numeric: true)
      end

      def analyse_ref_dual(ret)
        m = /^(?<type>merge|dual)\((?<keys>.+)\)$/.match(ret[:id]) or
          return ret
        line = CSV.parse_line(m[:keys], liberal_parsing: true) or return ret
        line.size > 1 or return ret
        ret[:id] = line.first
        ret[m[:type].to_sym] = line[1..-1].map(&:strip)
        ret
      end

      def analyse_ref_code(code)
        ret = { id: code }
        code.nil? || code.empty? and return ret
        analyse_ref_code_csv(ret) ||
          analyse_ref_code_nested(ret)
      end

      def analyse_ref_code_csv(ret)
        ret[:id].include?("=") or return nil
        line = CSV.parse_line(ret[:id], liberal_parsing: true) or return nil
        a = analyse_ref_code_csv_breakup(line)
        analyse_ref_code_csv_map(a)
      rescue StandardError
        nil
      end

      def analyse_ref_code_csv_breakup(line)
        line.each_with_object({}) do |x, m|
          kv = x.split("=", 2)
          kv.size == 1 and kv = ["code", kv.first]
          m[kv[0].to_sym] = kv[1].delete_prefix('"').delete_suffix('"')
            .delete_prefix("'").delete_suffix("'")
        end
      end

      def analyse_ref_code_csv_map(source)
        source.each_with_object({}) do |(k, v), ret|
          case k
          when :dropid, :hidden, :nofetch
            ret[k] = v == "true"
          when :repo, :path
            ret[:type] = k.to_s
            ret[:key] = v
            ret[:nofetch] = true
            source[:code] or
              ret[:id] = v.sub(%r{^[^/]+/}, "")
          when :"local-file"
            ret[:localfile] = v
          when :number
            if source[:code] then ret[:usrlabel] = "(#{v})"
            else ret[:numeric] = true
            end
          when :usrlabel
            ret[:usrlabel] = "(#{v})"
          when :code then ret[:id] = v
          end
        end
      end

      # ref id = (usrlbl)code[:-]year
      # code = \[? number \]? | ident | nofetch(code) | hidden(code) |
      # dropid(code) | # (repo|path):(key,code) | local-file(source,? key) |
      # merge(code, code) | dual(code, code)
      def analyse_ref_code_nested(ret)
        analyse_ref_dual(
          analyse_ref_numeric(
            analyse_ref_repo_path(
              analyse_ref_dropid(
                analyse_ref_hidden(
                  analyse_ref_nofetch(analyse_ref_localfile(ret)),
                ),
              ),
            ),
          ),
        )
      end

      # if no year is supplied, interpret as no_year reference
      def no_year_generic_ref(code)
        /^(BSI|BS)\b/.match?(code)
      end

      def plaintxt
        { format: "text/plain" }
      end

      def ref_attributes(match)
        code = analyse_ref_code(match[:code])

        { id: match[:anchor], type: "standard",
          suppress_identifier: code[:dropid] || nil }
      end

      MALFORMED_REF = <<~REF.freeze
        no anchor on reference, markup may be malformed: see
        https://www.metanorma.com/author/topics/document-format/bibliography/ ,
        https://www.metanorma.com/author/iso/topics/markup/#bibliographies
      REF

      def ref_normalise(ref)
        ref.gsub("&amp;amp;", "&amp;").gsub(%r{^<em>(.*)</em>}, "\\1")
      end

      def ref_normalise_no_format(ref)
        ref.gsub("&amp;amp;", "&amp;")
          .gsub(">\n", "> \n")
      end

      def skip_docid
        <<~XPATH.strip.freeze
          @type = 'DOI' or @type = 'doi' or @type = 'ISSN' or @type = 'issn' or @type = 'ISBN' or @type = 'isbn' or starts-with(@type, 'ISSN.') or starts-with(@type, 'ISBN.') or starts-with(@type, 'issn.') or starts-with(@type, 'isbn.')
        XPATH
      end
    end
  end
end
