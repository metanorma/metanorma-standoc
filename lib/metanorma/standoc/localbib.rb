require "relaton_bib"

module Metanorma
  module Standoc
    class LocalBiblio
      def initialize(node, localdir, parent)
        @file_bibdb = {}
        @localdir = localdir
        @parent = parent
        read_files(node)
      end

      def read_files(node)
        if node.attr("relaton-data-source")
          init_file_bibdb1(node.attr("relaton-data-source"), "default")
        else
          node.attributes.each do |k, v|
            /^relaton-data-source-.+/.match?(k) or next
            init_file_bibdb1(v, k.sub(/^relaton-data-source-/, ""))
          end
        end
      end

      def init_file_bibdb_config(defn, key)
        /=/.match?(defn) or defn = "file=#{defn}"
        values = defn.split(",").map { |item| item.split /\s*=\s*/ }.to_h
        values["key"] = key
        values["format"] ||= "bibtex" # all we currently suppoort
        values
      end

      def init_file_bibdb1(defn, key)
        v = init_file_bibdb_config(defn, key)
        r = read_file(v)
        @file_bibdb[v["key"]] =
          case v["format"]
          when "bibtex"
            RelatonBib::BibtexParser.from_bibtex(r)
          else
            format_error(v)
          end
      end

      def read_file(config)
        f = File.join(@localdir, config["file"])
        File.exist?(f) or return file_error(config)
        File.read(f)
      end

      def file_error(config)
        msg = "Cannot process file #{config['file']} for local relaton " \
              "data source #{config['key']}"
        @parent.fatalerror << msg
        @parent.log.add("Bibliography", nil, msg)
        ""
      end

      def format_error(config)
        msg = "Cannot process format #{config['format']} for local relaton " \
              "data source #{config['key']}"
        @parent.fatalerror << msg
        @parent.log.add("Bibliography", nil, msg)
        {}
      end

      def get(id, file = default)
        ret = @file_bibdb.dig(file, id) and return ret

        msg = "Cannot find reference #{id} for local relaton " \
              "data source #{file}"
        @parent.fatalerror << msg
        @parent.log.add("Bibliography", nil, msg)
        Nokogiri::XML("<bibitem/>")
      end
    end
  end
end
