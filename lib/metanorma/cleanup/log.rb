module Metanorma
  module Standoc
    class Cleanup
      def relaton_iev_cleanup(xmldoc)
        _, err = RelatonIev::iev_cleanup(xmldoc, @bibdb)
        err.each do |e|
          @log.add("RELATON_5", nil, params: e)
        end
      end

      RELATON_SEVERITIES =
        { "INFO": "RELATON_4", "WARN":  "RELATON_3", "ERROR":  "RELATON_2",
          "FATAL": "RELATON_1", "UNKNOWN":  "RELATON_4" }.freeze

      def relaton_log_cleanup(_xmldoc)
        @relaton_log or return
        @relaton_log.rewind
        @relaton_log.string.split(/(?<=})\n(?={)/).each do |l|
          e = JSON.parse(l)
          relaton_log_add?(e) and
            @log.add(RELATON_SEVERITIES[e["severity"].to_sym], e["key"],
                     params: [e["message"]])
        end
      end

      def relaton_log_add?(entry)
        entry["message"].include?("Fetching from") and return false
        entry["message"].include?("Downloaded index from") and return false
        entry["message"].start_with?("Found:") or return true
        id = /^Found: `(.+)`$/.match(entry["message"]) or return true
        !relaton_key_eqv?(entry["key"], id[1])
      end

      def relaton_key_eqv?(sought, found)
        sought = sought.sub(" (all parts)", "").sub(/:(19|20)\d\d$/, "")
        found = found.sub(" (all parts)", "").sub(/:(19|20)\d\d$/, "")
        sought.end_with?(found)
      end
    end
  end
end
