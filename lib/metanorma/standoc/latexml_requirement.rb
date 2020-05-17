require_relative "./requirement"

module Metanorma
  module Standoc
    class LatexmlRequirement < Requirement
      @recommended_version = '0.8.4'
      @minimal_version = '0.8.0'

      def initialize
        version_output, = Open3.capture2e("latexml --VERSION")
        version = version_output&.match(%r{\d+(.\d+)*})

        if version.to_s.empty?
          @error_message = "LaTeXML is not available. (Or is PATH not setup properly?)"\
            " You must upgrade/install LaTeXML to a version higher than `#{@recommended_version}`"

        elsif Gem::Version.new(version) < Gem::Version.new(@minimal_version)
          @error_message = "Minimal supported LaTeXML version is `#{@minimal_version}` "\
              "Version `#{version}` found; recommended version is `#{@recommended_version}`"

        elsif Gem::Version.new(version) < Gem::Version.new(@recommended_version)
          version = "unknown" if version.to_s.empty?
          header_msg = "latexmlmath version `#{version}` below `#{@recommended_version}`!"
          suggestion = if Gem.win_platform?
                         "cmd encoding is set to UTF-8 with `chcp 65001`"
                       else
                         "terminal encoding is set to UTF-8 with `export LANG=en_US.UTF-8`"
                       end

          @error_message = "WARNING #{header_msg} Please sure that #{suggestion} command."

          @cmd = 'latexmlmath --strict --preload=amsmath -- -'
          @cmd2 = 'latexmlmath --strict -- -'
        else
          @cmd = 'latexmlmath --strict --preload=amsmath --inputencoding=UTF-8 -- -'
          @cmd2 = 'latexmlmath --strict --inputencoding=UTF-8 -- -'
        end
      rescue
        @error_message = "LaTeXML is not available. (Or is PATH not setup properly?)"\
            " You must upgrade/install LaTeXML to a version higher than `#{@recommended_version}`"
      end

      def satisfied(abort = false)
        unless @error_message.nil?
          if abort
            abort @error_message
          else
            warn @error_message
          end
        end

        @error_message.nil?
      end

      def cmd
        abort @error_message unless @error_message.nil?

        [@cmd, @cmd2]
      end
    end
  end
end
