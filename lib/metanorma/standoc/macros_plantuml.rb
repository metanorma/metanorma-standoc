module Metanorma
  module Standoc
    class PlantUMLBlockMacroBackend
      # https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      def self.plantuml_installed?
        cmd = "plantuml"
        exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
        ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
        raise "PlantUML not installed"
      end

      def self.run(umlfile, outfile)
        system "plantuml #{umlfile.path}" or (warn $? and return false)
        i = 0
        until !Gem.win_platform? || File.exist?(outfile) || i == 15
          sleep(1)
          i += 1
        end
        File.exist?(outfile)
      end

      # if no :imagesdir: leave image file in plantuml
      # sleep need for windows because dot works in separate process and
      # plantuml process may finish earlier then dot, as result png file
      # maybe not created yet after plantuml finish
      #
      # # Warning: metanorma/metanorma-standoc#187
      # Windows Ruby 2.4 will crash if a Tempfile is "mv"ed.
      # This is why we need to copy and then unlink.
      def self.generate_file(parent, reader)
        localdir = Metanorma::Utils::localdir(parent.document)
        imagesdir = parent.document.attr("imagesdir")
        umlfile, outfile = save_plantuml parent, reader, localdir
        run(umlfile, outfile) or
          raise "No image output from PlantUML (#{umlfile}, #{outfile})!"
        umlfile.unlink

        path = path_prep(localdir, imagesdir)
        filename = File.basename(outfile.to_s)
        FileUtils.cp(outfile, path) and outfile.unlink

        imagesdir ? filename : File.join(path, filename)
      end

      def self.path_prep(localdir, imagesdir)
        path = Pathname.new(localdir) + (imagesdir || "plantuml")
        File.writable?(localdir) or
          raise "Destination path #{path} not writable for PlantUML!"
        path.mkpath
        File.writable?(path) or
          raise "Destination path #{path} not writable for PlantUML!"
        # File.exist?(path) or raise "Destination path #{path} already exists for PlantUML!"
        path
      end

      def self.save_plantuml(_parent, reader, _localdir)
        src = prep_source(reader)
        /^@startuml (?<fn>[^\n]+)\n/ =~ src
        Tempfile.open(["plantuml", ".pml"], encoding: "utf-8") do |f|
          f.write(src)
          [f, File.join(File.dirname(f.path),
                        "#{fn || File.basename(f.path, '.pml')}.png")]
        end
      end

      def self.prep_source(reader)
        src = reader.source
        reader.lines.first.sub(/\s+$/, "").match /^@startuml($| )/ or
          src = "@startuml\n#{src}\n@enduml\n"
        %r{@enduml\s*$}m.match?(src) or
          raise "@startuml without matching @enduml in PlantUML!"
        src
      end

      def self.generate_attrs(attrs)
        %w(id align float title role width height alt)
          .inject({}) do |memo, key|
          memo[key] = attrs[key] if attrs.has_key? key
          memo
        end
      end
    end

    class PlantUMLBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :plantuml
      on_context :literal
      parse_content_as :raw

      def abort(parent, reader, attrs, msg)
        warn msg
        attrs["language"] = "plantuml"
        create_listing_block parent, reader.source,
                             (attrs.reject { |k, _v| k == 1 })
      end

      def process(parent, reader, attrs)
        PlantUMLBlockMacroBackend.plantuml_installed?
        filename = PlantUMLBlockMacroBackend.generate_file(parent, reader)
        through_attrs = PlantUMLBlockMacroBackend.generate_attrs attrs
        through_attrs["target"] = filename
        create_image_block parent, through_attrs
      rescue StandardError => e
        abort(parent, reader, attrs, e.message)
      end
    end
  end
end
