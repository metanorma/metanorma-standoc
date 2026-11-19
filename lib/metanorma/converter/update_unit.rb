module Metanorma
  module Standoc
    # AsciiDoc surface for update units (metanorma-document
    # Components::UpdateUnits). A clause declares itself an update unit
    # with `update-unit=<unit>`; its amendment records are structured
    # data read from a YAML register (`update-records=<path>` on the
    # clause, or the `:update-records:` document attribute), keyed by
    # unit name or clause anchor. The records are emitted as the
    # division's `<update-unit>`; Records of Updates are derived from
    # them downstream, never authored as tables.
    #
    # The clause-parse hook is named `clause_update_unit_parse`, not
    # `update_unit_parse`: every converter inherits this module, and
    # released flavors already define same-named methods of their own
    # (metanorma-iho 1.4.6 parses its update-unit section identifiers
    # through `update_unit_parse(val)`); an unnamespaced hook name would
    # shadow theirs and break every clause parse with an arity error.
    module UpdateUnit
      def clause_update_unit_parse(xml, node)
        unit = node.attr("update-unit") or return
        record = update_unit_record(node, unit)
        record ||= ::Metanorma::Document::Components::UpdateUnits::UpdateUnit
          .new(unit: unit)
        record.unit = unit
        xml << record.to_xml
      end

      def update_unit_record(node, unit)
        path = node.attr("update-records") ||
          node.document.attr("update-records") or return nil
        register = update_unit_register(path, node) or return nil
        rec = register[unit] || register[node.id]
        rec or @log.add("STANDOC_70", node, params: [unit, path])
        rec
      end

      def update_unit_register(path, node)
        @update_unit_registers ||= {}
        @update_unit_registers.fetch(path) do
          @update_unit_registers[path] = update_unit_load(path, node)
        end
      end

      def update_unit_load(path, node)
        file = File.expand_path(path, @localdir || Dir.pwd)
        unless File.exist?(file)
          @log.add("STANDOC_71", node, params: [path])
          return nil
        end
        ::Metanorma::Document::UpdateUnits
          .load_register(File.read(file, encoding: "utf-8"))
      rescue ArgumentError, Psych::Exception, Lutaml::Model::Error => e
        @log.add("STANDOC_72", node, params: [path, e.message])
        nil
      end
    end
  end
end
