require_relative "./requirement"

module Metanorma
  module Standoc
    class LatexmlRequirement < Requirement
      def initialize
        @recommended_version = '0.8.4'
        @minimal_version = '0.8.0'
        version_output, = Open3.capture2e("latexml --VERSION")
        @actual_version = version_output&.match(%r{\d+(.\d+)*})
      end

      def satisfied
        version = @actual_version

        if version.to_s.empty?
          abort "LaTeXML not found in PATH, please make sure that you installed LaTeXML"
        end

        if Gem::Version.new(version) < Gem::Version.new(@minimal_version)
          abort "Minimal supported LaTeXML version is #{@minimal_version} "\
                "found #{version}, recommended version is #{@recommended_version}"
        end
        
        if Gem::Version.new(version) < Gem::Version.new(@recommended_version)
          version = "unknown" if version.to_s.empty?
          header_msg = "WARNING latexmlmath version #{version} below #{@recommended_version}!"
          suggestion = if Gem.win_platform?
                         "cmd encoding is set to UTF-8 with `chcp 65001`"
                       else
                         "terminal encoding is set to UTF-8 with `export LANG=en_US.UTF-8`"
                       end

          warn "#{header_msg} Please sure that #{suggestion} command"

          @cmd = "latexmlmath --preload=amsmath -- -"
        else
          @cmd = "latexmlmath --preload=amsmath --inputencoding=UTF-8 -- -"
        end
      end

      def cmd
        if @cmd.nil?
          satisfied
        end

        @cmd
      end
    end
  end
end