module Metanorma
  module Standoc
    module Cleanup
      # The boilerplate file is in Liquid AsciiDoc format
      # (technically, `boilerplate.adoc.liquid`).
      #
      # This file is processed separately from the main Metanorma document and
      # therefore is oblivious of the `{{ concept-mention }}` syntax.
      #
      # Due to historic reasons, the Liquid objects being evaluated in the
      # boilerplate document are XML strings. Notably these are the document
      # metadata, that are extracted from the already generated Metanorma XML.
      #
      # These XML strings are then passed into the AsciiDoc macros such as
      # `span:publisher[...]`.
      #
      # Here, we need to interpolate the XML strings into the AsciiDoc macros
      # without breaking the AsciiDoc syntax.
      #
      # EXAMPLE 1: `mailto:{{ pub_email }}[]`, we need to
      # convert it to:
      # `mailto:{{ pass-format:metanorma[++pub_email_xml++] }}[]`
      #
      # EXAMPLE 2: `link:{{ pub_uri}}[{{ pub_address }}, {{ pub_uri }}]`
      # We need to convert it to:
      # `link:{{ pass-format:metanorma[++pub_uri_xml++] }}[{{
      # pass-format:metanorma[++pub_address_xml++] }}, {{
      # pass-format:metanorma[++pub_uri_xml++] }}]`
      #
      # NOTE: The boilerplate may use macros that contain one or more
      # `{{ ... }}` in the target, and can contain spaces in them.
      #
      # NOTE: The routine needs to handle cases where the content
      # contains an escaped closing bracket `\]`.

      ADOC_MACRO_PATTERN = /\S+:[^\[\n]*\[[^\]\\]*(?:\\.[^\]\\]*)*\]/

      # Replace {{ ... }} with {{ pass-format:metanorma:[...] }} to preserve any
      # XML markup provided by Metanorma XML Metadata content, through the
      # `pass-format:metanorma` command.
      #
      # * If `{{ ... }}` is inside an Asciidoc macro, we have to wrap with
      #   pass-format:metanorma:[...\].
      # * If this is a macro target (e.g. `mailto:{{x}}[]`, body: mailto:[{{x}}])
      #   then do not use pass-format:metanorma.

      def boilerplate_read(file)
        ret = File.read(file, encoding: "UTF-8")
        /\.adoc(\.liquid)?$/.match?(file) or return ret

        # Split content into macro and non-macro parts
        parts = ret.split(/(#{ADOC_MACRO_PATTERN})/o)

        parts.map.with_index do |part, index|
          if index.odd? && valid_macro?(part)
            # This is a macro - leave unchanged
            part
          else
            # Not a macro - wrap {{ }} patterns
            part.gsub(/(?<!\{)(\{\{[^{}]+\}\})(?!\})/,
                      "pass-format:metanorma[++\\1++]")
          end
        end.join
      end

      private

      def valid_macro?(text)
        # Simple validation - does it look like a macro?
        text.match?(/^\S+:[^\[]*\[.*\]$/)
      end
    end
  end
end
