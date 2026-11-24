# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module UniversalSchema
        # Reproducible producer from pinned, locally supplied schema trees.
        # The exported configuration contains only runtime selection/integrity data.
        class SourceBuilder
          def initialize(metadata_parents:)
            @metadata_parents = metadata_parents
          end

          def build(sources:)
            profiles = sources.map do |source|
              compiler = compiler_for(source)
              compiled = compiler.compile(source.fetch(:entry))
              xml = case source[:model]
                    when nil then compiled.xml
                    when "iso" then ISOModelGrammar.adapt(compiled.xml)
                    else raise Error, "unknown model realization #{source[:model].inspect}"
                    end
              Profile.new(id: source.fetch(:id), xml: xml,
                          flavor: source.fetch(:flavor, source.fetch(:id)),
                          flavor_attribute: source.fetch(:flavor_attribute, true),
                          representation_attribute: source.fetch(:representation_attribute, true))
            end
            result = Producer.new(profiles: profiles, metadata_parents: @metadata_parents).produce
            xml = compact(result.xml)
            manifest = result.manifest.merge("rng_sha256" => Digest::SHA256.hexdigest(xml))
            Result.new(xml: xml, manifest: manifest)
          end

          private

          def compiler_for(source)
            case source[:migration]
            when nil
              Schema::Compiler.new(root: source.fetch(:root))
            when "un-admonition-attributes-1"
              UNCompiler.new(root: source.fetch(:root), entry: source.fetch(:entry))
            else
              raise Error, "unknown explicit source migration #{source[:migration].inspect}"
            end
          end

          def compact(xml)
            document = Nokogiri::XML(xml) { |config| config.strict.nonet }
            # Foreign RNG annotations and XML comments have no grammar meaning.
            # Keep namespace declarations and literal value/param/name text.
            document.xpath("//*").select { |node| node.namespace&.href != NS }.each(&:remove)
            document.xpath("//comment()").each(&:remove)
            document.xpath("//text()").each do |node|
              node.remove if node.text.strip.empty? && !%w(value param name).include?(node.parent.name)
            end
            output = document.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
            Nokogiri::XML::RelaxNG(output)
            output
          end
        end
      end
    end
  end
end
