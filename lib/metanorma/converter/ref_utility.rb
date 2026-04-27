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
        year&.sub(/^([0-9]+)-.*$/, "\\1")
      end

      def conditional_date(bib, match, noyr)
        if match.names.include?("year") && !match[:year].nil?
          bib.date(type: "published") do |d|
            (noyr and d.on "--") or set_date_range(d, norm_year(match[:year]))
          end
        end
      end

      def use_my_anchor(ref, id, opt)
        elem = ref.parent.elements.last
        elem["anchor"] = id
        add_id(elem)
        a = opt[:hidden] and elem["hidden"] = a
        a = opt[:amend] and elem["amend"] = a
        a = opt[:dropid] and elem["suppress_identifier"] = a
        ref
      end

      def docid(bib, code, codetype = nil)
        type, code1 = if /^\[\d+\]$|^\(.+\).*$/.match?(code)
                        ["metanorma", mn_code(code)]
                      elsif docid_untyped?(code, codetype)
                        [nil, code]
                      else @bibdb&.docid_type(code) || [nil, code]
                      end
        code1.sub!(/^nofetch\((.+)\)$/, "\\1")
        add_noko_elem(bib, "docidentifier", code1, type: type)
      end

      def docid_untyped?(code, codetype)
        %w(attachment repo path).include?(codetype) ||
          code.strip.empty? || /^\d+$/.match?(code)
      end

      def docnumber(bib, code)
        code or return
        add_noko_elem(bib, "docnumber", @c.decode(code).sub(/^[^\d]*/, ""))
      end

      def mn_code(code)
        # Handle balanced parentheses at the start of the string
        balance, remainder = extract_balanced_parentheses(code)
        balance and return "[#{balance}]"
        remainder
          .sub(/^dropid\((.+)\)$/, "\\1")
          .sub(/^hidden\((.+)\)$/, "\\1")
          .sub(/^nofetch\((.+)\)$/, "\\1")
          .sub(/^local-file\((.+)\)$/, "\\1")
          .sub(/^amend\((.+)\)$/, "\\1")
      end

      def analyse_ref_repo_path(ret)
        %i(repo path attachment).each do |type|
          ret[type] or next
          id = if ret[:id].empty?
                 if type == :attachment then "(#{ret[type]})"
                 else ret[type].sub(%r{^[^/]+/}, "")
                 end
               else ret[:id]
               end
          ret.merge!(id: id, type: type.to_s, key: ret[type], nofetch: true)
        end
        ret
      end

      def analyse_ref_numeric(ret)
        /^\d+$/.match?(ret[:id]) or return ret
        ret.merge(numeric: true)
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
          when :repo, :path, :attachment
            ret[:type] = k.to_s
            ret[:key] = v
            ret[:nofetch] = true
            source[:code] or
              ret[:id] = v == :attachment ? nil : v.sub(%r{^[^/]+/}, "")
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

      def analyse_ref_code_nested(ret)
        opts, id = parse_ref_code_nested({}, ret[:id])
        ret[:id] = id
        ret.merge!(opts)
        analyse_ref_numeric(ret)
        analyse_ref_repo_path(ret)
        ret
      end

      # ref id = (usrlbl)code[:-]year
      # code = \[? number \]? | ident | nofetch(code) | hidden(code) |
      # dropid(code) | amend(code) | (repo|path|attachment):(key,code) |
      # local-file(source,? key) |
      # merge(code, code) | dual(code, code)
      def parse_ref_code_nested(ret, ident)
        keys = %w(nofetch hidden dropid local-file repo path attachment merge
                  dual amend)
        if (m = /^(?<key>[a-z-]+):?\((?<val>.*)\)$/.match(ident)) &&
            keys.include?(m[:key])
          case m[:key]
          when "nofetch", "hidden", "dropid", "amend"
            ret[m[:key].to_sym] = true
            parse_ref_code_nested(ret, m[:val])
          when "repo", "path", "attachment"
            kv = m[:val].split(",", 2).map(&:strip)
            ret[m[:key].to_sym] = kv[0]
            parse_ref_code_nested(ret, kv.size == 1 ? "" : kv[1])
          when "local-file"
            kv = m[:val].split(",", 2).map(&:strip)
            source = kv.size == 1 ? "default" : kv[0]
            ret[:localfile] = source
            parse_ref_code_nested(ret, kv[-1])
          when "merge", "dual"
            line = CSV.parse_line(m[:val],
                                  liberal_parsing: true) or return [ret, ident]
            line.size > 1 or return [ret, ident]
            ret[:id] = line.first
            ret[m[:key].to_sym] = line[1..].map(&:strip)
            [ret, ret[:id]]
          end

        else [ret, ident]
        end
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
        { anchor: match[:anchor], id: "_#{UUIDTools::UUID.random_create}",
          type: "standard",
          suppress_identifier: code[:dropid] || nil }
      end

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

      private

      def extract_balanced_parentheses(code)
        code.start_with?("(") or return [nil, code]
        paren_count = 0
        # Find the matching closing parenthesis
        code.each_char.with_index do |char, index|
          case char
          when "(" then paren_count += 1
          when ")"
            paren_count -= 1
            paren_count.zero? or next
            # Found the matching closing parenthesis
            content = code[1...index] # Extract content between parentheses
            remaining = code[(index + 1)..] || "" # Get remaining string
            return [content, remaining]
          end
        end
        # If we get here, parentheses are unbalanced - return original
        [nil, code]
      end
    end
  end
end
