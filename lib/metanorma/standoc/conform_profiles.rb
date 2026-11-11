# frozen_string_literal: true

module Metanorma
  module Standoc
    # The Metanorma conformance-profile registry — one resolution engine
    # for every image-conformance type (svg_conform today, png_conform
    # when it exposes profile selection on its service path, and any
    # future engine).
    #
    # MECE partition:
    # - Registry (here): resolution semantics only — reserved words
    #   (none/off/disabled), the owned "metanorma" default, scoped names
    #   (flavor dir, then standoc dir), the engine-prefix opt-in
    #   ("svg:<name>" / "png:<name>"), direct path loads, error messages.
    # - Engine adapters (per-type methods on Standoc::Validate): loading
    #   through each engine's own API.
    # - Flavors: their profile files — one directory per type
    #   (lib/metanorma/<flavor>/<type>_conform_profile/), addressable by
    #   bare name; flavors override +conform_profile_dir+.
    # - Documents: selection via the <type>-conform-profile attribute.
    module ConformProfiles
      RESERVED_DISABLE = %w(none off disabled).freeze
      RESERVED_DEFAULT = "metanorma"

      class NotFound < StandardError; end

      # A per-type registry bound to its directories and engine prefix.
      class Registry
        def initialize(type:, standoc_dir:, flavor_dir: nil)
          @type = type.to_s
          @standoc_dir = standoc_dir
          @flavor_dir = flavor_dir
        end

        # @return [[:disabled], [:file, String], [:engine, String]]
        def resolve(value)
          value = value&.strip
          return [[:file], default_file].flatten if value.nil? || value.empty?
          return [:disabled] if disabled?(value)
          return [:engine, engine_name(value)] if engine_qualified?(value)

          file = named_file(@flavor_dir, value) ||
                 named_file(@standoc_dir, value) || path_file(value)
          raise NotFound, unknown_message(value) unless file

          [:file, file]
        end

        def default_file
          file = named_file(@flavor_dir, RESERVED_DEFAULT) ||
                 named_file(@standoc_dir, RESERVED_DEFAULT)
          raise NotFound, "the owned #{RESERVED_DEFAULT}.yml baseline " \
                          "is missing from #{@standoc_dir}" unless file

          file
        end

        def disabled?(value)
          RESERVED_DISABLE.include?(value.downcase)
        end

        def engine_qualified?(value)
          value.start_with?("#{@type}:")
        end

        def engine_name(value)
          value.delete_prefix("#{@type}:")
        end

        def named_file(dir, name)
          return nil if dir.nil?

          path = File.join(dir, "#{name}.yml")
          File.exist?(path) ? path : nil
        end

        def path_file(value)
          return nil unless value.end_with?(".yml") || value.include?("/")

          File.exist?(value) ? value : nil
        end

        def unknown_message(value)
          "unknown #{@type}-conform-profile #{value.inspect}; available: " \
            "#{RESERVED_DISABLE.join(', ')} (disable validation), " \
            "#{available_names.join(', ')}, a .yml path, or " \
            "'#{@type}:<name>' for a #{@type}_conform gem profile"
        end

        def available_names
          [@flavor_dir, @standoc_dir].flat_map do |dir|
            next [] if dir.nil?

            Dir.glob(File.join(dir, "*.yml")).map { |f| File.basename(f, ".yml") }
          end.uniq.sort
        end
      end
    end
  end
end
