# frozen_string_literal: true

require "nokogiri"
require "json"
require "digest"
require_relative "schema_compiler"

module Metanorma
  module Standoc
    class Validate
      # A single grammar artifact with closed, explicitly discriminated flavor
      # profiles. Each branch retains its own ref scope and original content
      # constraints. Runtime consumers select a declared profile, not a file.
      module UniversalSchema
        NS = "http://relaxng.org/ns/structure/1.0"
        XSD = "http://www.w3.org/2001/XMLSchema-datatypes"
        PRIVATE_FACTS_NS = "urn:metanorma:iso:validation-projection:1"
        PAYLOAD = "fmt-ladl-label-data"
        METADATA_ATTRIBUTES = %w(local global value direction global-direction labeller).freeze
        class Error < ArgumentError; end

        Result = Data.define(:xml, :manifest)

        class Profile
          attr_reader :id, :xml, :flavor, :representations, :provenance, :flavor_attribute, :representation_attribute

          def initialize(id:, xml:, flavor: id, representations: %w(semantic presentation), provenance: {}, flavor_attribute: true, representation_attribute: true)
            @id, @xml, @flavor = id.to_s, xml, flavor.to_s
            @flavor_attribute, @representation_attribute = flavor_attribute, representation_attribute
            unless [true, false].include?(flavor_attribute) && [true, false].include?(representation_attribute)
              raise Error, "profile discriminator flags must be booleans"
            end
            @representations = representations.map(&:to_s).freeze
            @provenance = provenance.dup.freeze
            unless /\A[a-z][a-z0-9_-]*\z/.match?(@id) && !@flavor.empty?
              raise Error, "invalid profile identity #{id.inspect}"
            end
            unless @representations.any? && (@representations - %w(semantic presentation)).empty?
              raise Error, "profile #{@id}: representation must be semantic or presentation"
            end
            freeze
          end
        end

        class Producer
          def initialize(profiles:, metadata_parents:)
            @profiles = profiles
            @metadata_parents = metadata_parents.map(&:to_s).uniq.freeze
            if @profiles.empty? || @profiles.map(&:id).uniq.size != @profiles.size
              raise Error, "profiles must be nonempty with unique identities"
            end
            unless @metadata_parents.all? { |name| /\A[a-z][a-z0-9_-]*\z/.match?(name) }
              raise Error, "metadata parent names must be explicit local element names"
            end
          end

          def produce
            document = Nokogiri::XML::Document.new
            grammar = Nokogiri::XML::Node.new("grammar", document)
            grammar.add_namespace_definition(nil, NS)
            document.root = grammar
            start = element(grammar, "start")
            choice = element(start, "choice")
            manifest = []
            occupied = {}
            @profiles.each do |profile|
              branches = profile.representations.map do |representation|
                Branch.new(profile, representation, metadata_parents: @metadata_parents).build
              end
              signatures = branches.map { |branch| branch.fetch(:roots) }.uniq
              raise Error, "profile #{profile.id}: inconsistent representation roots" unless signatures.size == 1

              signatures.first.each do |signature|
                previous = (occupied[signature] || []).find do |item|
                  !item.flavor_attribute || !profile.flavor_attribute || item.flavor == profile.flavor
                end
                if previous
                  raise Error, "overlapping profile discriminators: #{previous.id} and #{profile.id}"
                end
                (occupied[signature] ||= []) << profile
              end
              branches.each { |branch| choice.add_child(branch.fetch(:grammar)) }
              manifest << { "id" => profile.id, "flavor" => profile.flavor,
                            "representations" => profile.representations,
                            "roots" => signatures.first,
                            "flavor_attribute" => profile.flavor_attribute,
                            "representation_attribute" => profile.representation_attribute }
            end
            xml = document.to_xml
            Nokogiri::XML::RelaxNG(xml)
            Result.new(xml: xml, manifest: {
                         "schema" => "metanorma-shared-semantic-schema/1",
                         "rng_sha256" => Digest::SHA256.hexdigest(xml),
                         "profiles" => manifest,
                         "presentation_metadata" => { "element" => PAYLOAD,
                                                      "attributes" => METADATA_ATTRIBUTES,
                                                      "parents" => @metadata_parents },
                         "forbidden_namespaces" => [PRIVATE_FACTS_NS],
                       })
          rescue Nokogiri::XML::SyntaxError => error
            raise Error, "combined discriminated grammar is invalid: #{error.message}"
          end

          private

          def element(parent, name)
            node = Nokogiri::XML::Node.new(name, parent.document)
            node.namespace = parent.namespace
            parent.add_child(node)
            node
          end
        end

        # Uses the one grammar plus its integrity-bound profile configuration.
        # The profile check prevents a valid document for B from being accepted
        # by a consumer explicitly configured for A.
        class Validator
          def initialize(xml:, manifest:)
            @manifest = JSON.parse(manifest.is_a?(String) ? manifest : JSON.generate(manifest))
            unless @manifest["schema"] == "metanorma-shared-semantic-schema/1" &&
                @manifest["rng_sha256"] == Digest::SHA256.hexdigest(xml)
              raise Error, "shared grammar/configuration integrity mismatch"
            end
            profiles = @manifest["profiles"]
            unless profiles.is_a?(Array) && profiles.any? && profiles.map { |item| item["id"] }.uniq.size == profiles.size &&
                profiles.all? { |item| [true, false].include?(item["flavor_attribute"]) && [true, false].include?(item["representation_attribute"]) }
              raise Error, "shared configuration requires unique profiles and explicit discriminator flags"
            end
            @schema = Nokogiri::XML::RelaxNG(xml)
          end

          def validate(document, flavor:, representation: nil)
            profile = @manifest.fetch("profiles").find { |item| item["id"] == flavor.to_s }
            raise Error, "unknown configured flavor #{flavor.inspect}" unless profile

            doc = document.is_a?(Nokogiri::XML::Document) ? document :
              Nokogiri::XML(document) { |config| config.strict.nonet }
            root = doc.root
            return ["document has no root"] unless root

            mode = profile["representation_attribute"] ? root["type"] : representation.to_s
            unless (!profile["flavor_attribute"] || root["flavor"] == profile["flavor"]) &&
                profile["representations"].include?(mode) && (!representation || mode == representation.to_s) &&
                profile["roots"].any? { |name| name["name"] == root.name && name["namespace"] == root.namespace&.href.to_s }
              return ["document does not match configured flavor #{flavor}"]
            end
            if mode == "semantic" && doc.xpath("//*[local-name() = $name]", nil, name: PAYLOAD).any? { |node| profile["roots"].any? { |r| r["namespace"] == node.namespace&.href.to_s } }
              return ["presentation metadata is forbidden in semantic representation"]
            end
            @schema.validate(doc).map(&:message)
          rescue Nokogiri::XML::SyntaxError => error
            [error.message]
          end
        end
      end
    end
  end
end

require_relative "universal_schema/branch"

require_relative "universal_schema/source_migrations"
require_relative "universal_schema/source_builder"
require_relative "universal_schema/iso_model_grammar"
