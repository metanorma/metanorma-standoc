require "asciidoctor/extensions"
require "fileutils"
require "uuidtools"
require "yaml"
require "logger"

require File.expand_path("../../datamodel/plantuml_adaptor", __FILE__)
require File.expand_path("../../datamodel/asciidoc_adaptor", __FILE__)

module Asciidoctor
  module Standoc
    class DataModelBlockMacro < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :datamodel
      on_context :literal
      parse_content_as :raw

      PLANTUML_PATH = ".."
      DATAMODEL_PLANTUML_PATH = "plantuml2"
      TYPE_MAP = {
        "class" => "classes",
        "enum" => "enums",
      }

      def process(parent, reader, attrs)
        localdir = Utils::localdir(parent.document)
        view_hash = YAML.parse(reader.lines.join("\n")).to_ruby
        fidelity = view_hash["fidelity"] || {}

        view_hash = process_imported_models(localdir, view_hash)
        view_wsd = process_view(localdir, view_hash)

        block = create_open_block parent, [], {}, content_model: :compound

        # section = create_section block, view_hash["title"], {}
        # block.blocks.push(section)

        view_to_image_figure(block, parent, view_wsd, view_hash, attrs)
        models_to_sections(block, view_hash) unless fidelity["hideMembers"]

        block
      end

      private

      def view_to_image_figure(block, parent, view_wsd, view_hash, attrs)
        copy_style_file(parent)

        image_filename = generate_image_file(parent, view_wsd)

        # puts "************ image_filename #{image_filename}"
        # puts "************ view_wsd #{view_wsd}"

        through_attrs = generate_attrs attrs
        through_attrs["target"] = image_filename
        through_attrs["title"] = view_hash["caption"]

        image_block = create_image_block block, through_attrs
        block.blocks.push(image_block)
      end

      def models_to_sections(block, view_hash)
        Asciidoctor::DataModel::AsciidocAdaptor.for_each("classes", view_hash) do |class_name, class_hash|
          class_fidelity = class_hash["fidelity"] || {}
          next if class_fidelity["skipSection"]

          # cannot trust id generation not to clash with existing titles
          section = create_section block, class_name, {"id" => UUIDTools::UUID.random_create.to_s}
          block.blocks.push(section)

          parse_content(
            block,
            class_hash["definition"] || "TODO: class #{class_name}'s definition"
          )

          content = Asciidoctor::DataModel::AsciidocAdaptor.class_attributes_to_asciidoc(class_name, class_hash["attributes"])

          parse_content(block, content)
        end

        Asciidoctor::DataModel::AsciidocAdaptor.for_each("enums", view_hash) do |enum_name, enum_hash|
          section = create_section block, enum_name, {}
          block.blocks.push(section)

          parse_content(
            block,
            enum_hash["definition"] || "TODO: enum #{enum_name}'s definition"
          )

          content = Asciidoctor::DataModel::AsciidocAdaptor.enum_values_to_asciidoc(enum_name, enum_hash["values"])

          parse_content(block, content)
        end
      end

      # if no :imagesdir: leave image file in plantuml
      def generate_image_file(parent, wsd_file)
        localdir = Utils::localdir(parent.document)
        system "plantuml #{wsd_file}"

        view_name_regexp = /(?<view_name>[^\/]+)\.wsd\Z/
        matched = view_name_regexp.match(wsd_file)
        view_name = matched[:view_name]
        outfile_imagesdir = parent.image_uri("#{view_name}.png")
        outfile_normal = "#{view_name}.png"

        # puts "************ outfile #{outfile_imagesdir}"
        # puts "************ outfile_name #{outfile_normal}"

        path = Pathname.new(wsd_file)
        # puts "************ path #{path}"

        # Execution path + source dir of main adoc file
        parent_path = Pathname.pwd + localdir

        imagesdir_path = parent_path + outfile_imagesdir
        # puts "************ imagesdir_path #{imagesdir_path}"
        image_path = path.dirname + outfile_normal
        # puts "************ image_path #{image_path}"

        if outfile_normal.to_s == outfile_imagesdir.to_s
          image_path.relative_path_from(parent_path).to_s
        else
          # Create :imagesdir: directory if it doesn't yet exist.
          FileUtils.mkdir_p imagesdir_path.dirname

          # Move the image into :imagesdir: directory.
          FileUtils.mv image_path.to_s, imagesdir_path.to_s

          # We use this path because Asciidoctor automatically appends
          # ":imagedir:", so we have to give without ":imagedir:"
          outfile_normal
        end
      end

      def generate_attrs attrs
        through_attrs = %w(id align float title role width height alt).
          inject({}) do |memo, key|
          memo[key] = attrs[key] if attrs.has_key? key
          memo
        end
      end

      def copy_style_file(parent)
        localdir = Utils::localdir(parent.document)
        outfile = "style.uml.inc"

        FileUtils.cp(
          File.expand_path("models/#{outfile}", localdir),
          File.expand_path("models/#{DATAMODEL_PLANTUML_PATH}/#{outfile}", localdir)
        ).to_s
      end

      def process_view(localdir, view_hash)
        view_hash = view_hash.merge({
          "classes" => {},
          "enums" => {},
          "relations" => view_hash["relations"] || [],
          "fidelity" => (view_hash["fidelity"] || {}).merge({
            "classes" => view_hash["classes"]
          }),
        })

        dir_name = File.expand_path("models/#{DATAMODEL_PLANTUML_PATH}/views", localdir)
        FileUtils.mkdir_p(dir_name)

        view_wsd = "#{dir_name}/#{view_hash["name"]}.wsd"

        File.open(view_wsd, "w") do |file|
          file.write(Asciidoctor::DataModel::PlantumlAdaptor.yml_to_plantuml(
            view_hash,
            PLANTUML_PATH
          ))
        end

        view_wsd
      end

      def process_imported_models(localdir, view_hash)
        imports = view_hash["imports"] || {}
        imports.reduce(view_hash) do |acc, (model_path, model_fidelity)|
          begin
            model_hash = YAML.load_file(Pathname.new(localdir) + "models/models/#{model_path}.yml")
            model_type = TYPE_MAP[model_hash["modelType"]]
            model_name = model_hash["name"] || model_path.gsub(/\//, "")

            model_hash = ({
              "relations" => [],
              "fidelity" => model_fidelity
            }).merge(model_hash)

            model_to_plantuml(localdir, model_path, {
              model_type => {
                model_name => model_hash
              }
            })

            acc.merge({
              model_type => (acc[model_type] || {}).merge(
                model_name => model_hash
              )
            })
          rescue Exception => err
            logger = Logger.new(STDOUT)
            logger.warn("Cannot import #{model_path} from view #{view_hash["name"]}!")
            logger.warn(err.message)
            acc
          end
        end
      end

      def model_to_plantuml(localdir, model_path, model_hash)
        (*model_dirs, model_name) = model_path.split("/")

        model_dir = model_dirs.join("/")
        dir_name = File.expand_path("models/#{DATAMODEL_PLANTUML_PATH}/models/#{model_dir}", localdir)
        FileUtils.mkdir_p(dir_name)

        File.open("#{dir_name}/#{model_name}.wsd", "w") do |file|
          file.write(Asciidoctor::DataModel::PlantumlAdaptor.yml_to_plantuml(
            model_hash,
            PLANTUML_PATH
          ))
        end
      end
    end
  end
end
