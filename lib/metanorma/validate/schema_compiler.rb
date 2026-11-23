# frozen_string_literal: true

require "nokogiri"
require "pathname"
require "digest"

module Metanorma
  module Standoc
    class Validate
      module Schema
        # Produces one self-contained RNG without widening its language.
        # Includes retain override/combine semantics; external grammars keep
        # their own scope. This is consolidation tooling, not a claim that a
        # standoc grammar already covers every flavor's structural deltas.
        class Compiler
          NS = "http://relaxng.org/ns/structure/1.0"
          CONTEXT = %w(ns datatypeLibrary).freeze
          COMPONENTS = %w(define start).freeze
          Result = Data.define(:xml, :sources)

          class Error < ArgumentError; end

          def initialize(root:)
            @root = Pathname.new(root).realpath
          end

          def compile(entry)
            @sources = {}
            grammar = load_grammar(resolve(entry, @root), [])
            xml = grammar.to_xml
            # A parser error here is a compilation failure, never a signal
            # to replace unsupported constructs with a wildcard grammar.
            Nokogiri::XML::RelaxNG(xml)
            Result.new(xml: xml, sources: @sources.dup.freeze)
          rescue Nokogiri::XML::SyntaxError => e
            raise Error, "compiled RelaxNG is invalid: #{e.message}"
          end

          private

          def resolve(href, directory)
            if href.to_s.match?(%r{\A[a-z][a-z0-9+.-]*:}i) ||
                href.to_s.include?("#") || href.to_s.include?("?")
              raise Error, "only local schema files are supported: #{href}"
            end
            path = directory.join(href).realpath
            unless path.to_s.start_with?(@root.to_s + File::SEPARATOR)
              raise Error, "schema reference escapes root: #{href}"
            end
            path
          rescue Errno::ENOENT => e
            raise Error, "missing schema reference #{href}: #{e.message}"
          end

          def source_bytes(path)
            path.binread
          end

          def load_grammar(path, stack)
            if stack.include?(path)
              raise Error, "cyclic schema references: #{(stack + [path]).join(' -> ')}"
            end
            bytes = source_bytes(path)
            @sources[path.relative_path_from(@root).to_s] = Digest::SHA256.hexdigest(bytes)
            doc = Nokogiri::XML(bytes) { |config| config.strict.nonet }
            grammar = doc.root
            if doc.internal_subset || !rng?(grammar, "grammar")
              raise Error, "schema must be a DTD-free RNG grammar: #{path}"
            end
            expand_children(grammar, path, stack + [path])
            grammar
          end

          def expand_children(parent, path, stack)
            parent.element_children.to_a.each do |node|
              if rng?(node, "include")
                replacements = expand_include(node, path, stack)
                replacements.each { |replacement| node.add_previous_sibling(replacement) }
                node.remove
              elsif rng?(node, "externalRef")
                target = load_grammar(resolve(node["href"], path.dirname), stack)
                inherit_context(target, node)
                node.replace(target)
              else
                expand_children(node, path, stack)
              end
            end
          end

          def expand_include(node, path, stack)
            grammar = load_grammar(resolve(node["href"], path.dirname), stack)
            parts = components(grammar)
            overrides = components(node).select { |part| rng_component?(part) }
            overrides.group_by { |part| key(part) }.each do |name, replacements|
              unless parts.any? { |part| rng_component?(part) && key(part) == name }
                raise Error, "include overrides missing #{name.join(':')} in #{node['href']}"
              end
              parts.reject! { |part| rng_component?(part) && key(part) == name }
              replacements.each do |replacement|
                expand_children(replacement, path, stack)
                inherit_context(replacement, node)
                parts << replacement
              end
            end
            parts.each { |part| inherit_context(part, node) }
            parts
          end

          # div carries inherited ns/datatypeLibrary and namespace-prefix
          # declarations but introduces no grammar scope of its own.
          def components(container)
            container.element_children.flat_map do |part|
              if rng?(part, "div")
                components(part).each { |child| inherit_context(child, container) }
              else
                inherit_context(part, container)
                [part]
              end
            end
          end

          def inherit_context(target, source)
            CONTEXT.each do |attribute|
              target[attribute] = source[attribute] if !target[attribute] && source[attribute]
            end
            source.namespace_definitions.each do |binding|
              next if target.namespace_definitions.any? { |own| own.prefix == binding.prefix }

              target.add_namespace_definition(binding.prefix, binding.href)
            end
            target
          end

          def rng?(node, name)
            node && node.name == name && node.namespace&.href == NS
          end

          def rng_component?(node)
            node.namespace&.href == NS && COMPONENTS.include?(node.name)
          end

          def key(node)
            [node.name, node["name"]]
          end
        end
      end
    end
  end
end
