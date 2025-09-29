module Metanorma
  module Standoc
    module IsolatedConverter
      # Create an isolated Asciidoctor conversion that doesn't interfere with
      # the current converter's instance variables
      def isolated_asciidoctor_convert(content, options = {})
        # Track that we're in an isolated conversion (for nested calls)
        @isolated_conversion_stack ||= []
        @isolated_conversion_stack << true

        begin
          # Ensure we get a completely fresh Document and conversion context
          # Each call to Asciidoctor.convert creates a new Document with its own converter
          # This naturally isolates the conversion from the current instance variables

          # Save critical options that should be preserved from the current context
          preserved_options = extract_preserved_options(options)

          # Merge with isolated options to ensure clean state and skip validation
          isolated_options = preserved_options.merge(options).merge(
            attributes: (preserved_options[:attributes] || {}).merge(
              "novalid" => "", # Force no validation for isolated documents
            ),
          )

          # Perform the isolated conversion
          Asciidoctor.convert(content, isolated_options)
        ensure
          # Always pop from stack, even if conversion fails
          @isolated_conversion_stack.pop
        end
      end

      private

      # Extract options that should be preserved from the current conversion context
      def extract_preserved_options(user_opt)
        options = {}

        # Preserve safe mode to maintain security context
        options[:safe] = user_opt[:safe] if user_opt.key?(:safe)

        # Preserve local directory context if not explicitly overridden
        @localdir && !user_opt.key?(:base_dir) and
          options[:base_dir] = @localdir

        # Preserve attributes that are safe to share
        user_opt[:attributes].nil? && respond_to?(:safe_shared_attributes) and
          options[:attributes] = safe_shared_attributes

        options
      end

      # Define attributes that are safe to share between converter instances
      def safe_shared_attributes
        # Only include read-only or configuration attributes
        # Avoid any attributes that could cause state pollution
        {
          "source-highlighter" => "html-pipeline", # Use simple highlighter
          "nofooter" => "",
          "no-header-footer" => "",
        }
      end
    end
  end
end
