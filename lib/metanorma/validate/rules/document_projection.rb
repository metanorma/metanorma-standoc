# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module Rules
        # A model's semantic XML is the Schematron boundary. Keep its namespace
        # and source identity; findings refer to projection nodes, not invented
        # model-node objects. Existing XML callers retain their original nodes.
        class DocumentProjection
          attr_reader :xml, :source_model

          def self.for(input)
            return input if input.is_a?(self)

            if input.is_a?(Nokogiri::XML::Document) ||
                input.is_a?(Nokogiri::XML::Node)
              return new(input)
            end
            if defined?(::Metanorma::Document::Root) &&
                input.is_a?(::Metanorma::Document::Root)
              return new(parse_model(input), source_model: input)
            end

            raise RuleError, "rules require XML or a Metanorma Document root"
          end

          def self.parse_model(model)
            Nokogiri::XML(model.to_xml) { |config| config.strict.nonet }
          rescue Nokogiri::XML::SyntaxError => e
            raise RuleError, "invalid Document-model XML projection: #{e.message}"
          end

          def initialize(xml, source_model: nil)
            @xml = xml
            @source_model = source_model
            freeze
          end
        end
      end
    end
  end
end
