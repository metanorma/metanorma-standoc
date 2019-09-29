require "asciidoctor/extensions"
require "fileutils"
require "uuidtools"
require "yaml"

require_relative "./datamodel_block_macro"

module Asciidoctor
  module Standoc
    class AltTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :alt
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<admitted>#{out}</admitted>}
      end
    end

    class DeprecatedTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :deprecated
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<deprecates>#{out}</deprecates>}
      end
    end

    class DomainTermInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :domain
      parse_content_as :text
      using_format :short

      def process(parent, _target, attrs)
        out = Asciidoctor::Inline.new(parent, :quoted, attrs["text"]).convert
        %{<domain>#{out}</domain>}
      end
    end

    class HTML5RubyMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl
      named :ruby
      parse_content_as :text

      option :pos_attrs, %w(rpbegin rt rpend)

      def process(parent, target, attributes)
          rpbegin = '('
          rpend = ')'
        if attributes.size == 1 and attributes.key?("text")
          rt = attributes["text"]
        elsif attributes.size == 2 and attributes.key?(1) and attributes.key?("rpbegin")
          # for example, html5ruby:楽聖少女[がくせいしょうじょ]
          rt = attributes[1]
          rt ||= ""
        else
          rpbegin = attributes['rpbegin']
          rt = attributes['rt']
          rpend = attributes['rpend']
        end

        %(<ruby>#{target}<rp>#{rpbegin}</rp><rt>#{rt}</rt><rp>#{rpend}</rp></ruby>)
      end
    end

    class ToDoAdmonitionBlock < Extensions::BlockProcessor
      use_dsl
      named :TODO
      on_contexts :example, :paragraph

      def process parent, reader, attrs
        attrs['name'] = 'todo'
        attrs['caption'] = 'TODO'
        create_block parent, :admonition, reader.lines, attrs,
          content_model: :compound
      end
    end

    class ToDoInlineAdmonitionBlock < Extensions::Treeprocessor
      def process document
        (document.find_by context: :paragraph).each do |para|
          next unless /^TODO: /.match para.lines[0]
          parent = para.parent
          para.set_attr("name", "todo")
          para.set_attr("caption", "TODO")
          para.lines[0].sub!(/^TODO: /, "")
          todo = Block.new parent, :admonition, attributes: para.attributes,
            source: para.lines, content_model: :compound
          parent.blocks[parent.blocks.index(para)] = todo
        end
      end
    end

    class PlantUMLBlockMacroBackend
      # https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      def self.plantuml_installed?
        cmd = "plantuml"
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
        nil
      end

      # if no :imagesdir: leave image file in plantuml
      def self.generate_file parent, reader
        localdir = Utils::localdir(parent.document)
        fn = save_plantuml parent, reader, localdir
        umlfile = Pathname.new(localdir) + "plantuml" + "#{fn}.pml"
        system "plantuml #{umlfile}"
        # sleep need for windows because dot works in separate process and plantuml process may
        # finish erlier then dot, as result png file maybe not created yet after plantuml finish
        sleep(2) if Gem.win_platform?
        outfile = parent.image_uri("#{fn}.png")
        outfile_name = "#{fn}.png"
        if outfile == outfile_name
          (Pathname.new("plantuml") + outfile_name).to_s
        else
          FileUtils.mv (Pathname.new(localdir) + "plantuml" + outfile_name).to_s,
            (Pathname.new(localdir) + outfile).to_s
          (Pathname.new(outfile_name)).to_s
        end
      end

      def self.save_plantuml parent, reader, localdir
        src = reader.source
        reader.lines.first.sub(/\s+$/, "").match /^@startuml($| )/ or
          src = "@startuml\n#{src}\n@enduml\n"
        /^@startuml (?<fn>[^\n]+)\n/ =~ src
        fn ||= UUIDTools::UUID.random_create
        path = Pathname.new(localdir) + "plantuml"
        path.mkpath()
        (path + "#{fn}.pml").write(src)
        fn
      end

      def self.generate_attrs attrs
        through_attrs = %w(id align float title role width height alt).
          inject({}) do |memo, key|
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

      def process(parent, reader, attrs)
        if PlantUMLBlockMacroBackend.plantuml_installed?
          filename = PlantUMLBlockMacroBackend.generate_file parent, reader
          through_attrs = PlantUMLBlockMacroBackend.generate_attrs attrs
          through_attrs["target"] = filename
          create_image_block parent, through_attrs
        else
          warn "PlantUML not installed"
          # attrs.delete(1) : remove the style attribute
          attrs["language"] = "plantuml"
          create_listing_block parent, reader.source,
            attrs.reject { |k, v| k == 1 }
        end
      end
    end
  end
end
