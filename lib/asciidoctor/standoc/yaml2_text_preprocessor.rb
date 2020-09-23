# frozen_string_literal: true

require "asciidoctor/standoc/base_structured_text_preprocessor"

module Asciidoctor
  module Standoc
    class Yaml2TextPreprocessor < BaseStructuredTextPreprocessor
      # search document for block `yaml2text`
      #   after that take template from block and read file into this template
      #   example:
      #     [yaml2text,foobar.yaml]
      #     ----
      #     === {item.name}
      #     {item.desc}
      #
      #     {item.symbol}:: {item.symbol_def}
      #     ----
      #
      #   with content of `foobar.yaml` file equal to:
      #     - name: spaghetti
      #       desc: wheat noodles of 9mm diameter
      #       symbol: SPAG
      #       symbol_def: the situation is message like spaghetti at a kid's
      #
      #   will produce:
      #     === spaghetti
      #     wheat noodles of 9mm diameter
      #
      #     SPAG:: the situation is message like spaghetti at a kid's meal

      def initialize(config = {})
        super
        @config[:block_name] = "yaml2text"
      end

      protected

      def content_from_file(document, file_path)
        YAML.safe_load(
          File.read(relative_file_path(document, file_path)),
          [Date, Time])
      end
    end
  end
end
