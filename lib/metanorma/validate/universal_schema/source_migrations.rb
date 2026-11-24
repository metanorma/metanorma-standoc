# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module UniversalSchema
        # Explicit repair for the archived UN source typo. Include overrides
        # replace definitions; lifting the extension preserves required type
        # and the base URI/class/coverpage/notag attributes.
        class UNCompiler < Schema::Compiler
          attr_reader :migration

          def initialize(root:, entry:)
            super(root: root)
            @entry = Pathname.new(root).join(entry).realpath
          end

          private

          def source_bytes(path)
            bytes = super
            return bytes unless path == @entry

            doc = Nokogiri::XML(bytes) { |config| config.strict.nonet }
            ns = { "r" => NS }
            matches = doc.xpath("/r:grammar/r:include[@href='isodoc.rng']/r:define[@name='AdmonitionAttr']", ns)
            unless matches.size == 1 && matches.first["combine"] == "interleave" &&
                matches.first.xpath("./r:optional/r:attribute[@name='unnumbered']/r:data[@type='boolean']", ns).size == 1 &&
                matches.first.element_children.size == 1 &&
                matches.first.element_children.first.element_children.size == 1
              raise Error, "UN admonition migration source does not match the audited extension"
            end
            extension = matches.first
            extension["name"] = "AdmonitionAttributes"
            extension.unlink
            doc.root.add_child(extension)
            @migration = { "id" => "un-admonition-attributes-1",
                           "source_sha256" => Digest::SHA256.hexdigest(bytes),
                           "migrated_sha256" => Digest::SHA256.hexdigest(doc.to_xml),
                           "operation" => "rename extension and lift outside include; preserve base interleave" }
            doc.to_xml
          end
        end
      end
    end
  end
end
