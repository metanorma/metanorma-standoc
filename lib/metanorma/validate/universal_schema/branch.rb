# frozen_string_literal: true

module Metanorma
  module Standoc
    class Validate
      module UniversalSchema
        # Intersects a source grammar with exact existing root discriminators.
        # Guard definitions are cloned only along root-attribute paths: nested
        # document uses of those same definitions retain their source behavior.
        class Branch
          XMLNS = { "r" => NS }.freeze

          def initialize(profile, representation, metadata_parents:)
            @profile, @representation = profile, representation
            @metadata_parents = metadata_parents
            @document = Nokogiri::XML(profile.xml) { |config| config.strict.nonet }
            @grammar = @document.root
            unless rng?(@grammar, "grammar") && !@document.internal_subset &&
                @grammar.xpath(".//r:include | .//r:externalRef", XMLNS).empty?
              raise Error, "profile #{profile.id}: requires a DTD-free standalone grammar"
            end
            Nokogiri::XML::RelaxNG(profile.xml)
            @definitions = components(@grammar).select { |n| rng?(n, "define") }.group_by { |n| n["name"] }
            @aliases = {}
          end

          def build
            roots = components(@grammar).select { |n| rng?(n, "start") }.flat_map { |start| roots_in(start) }
            raise Error, "profile #{@profile.id}: no explicit document root" if roots.empty?

            signatures = roots.map { |root| signature(root) }.uniq
            roots = roots.map do |source|
              root = source.dup(1)
              inherit_context(root, source)
              root["ns"] = signature(source).fetch("namespace")
              clone_guard_refs(root)
              guards = {}
              guards["flavor"] = @profile.flavor if @profile.flavor_attribute
              guards["type"] = @representation if @profile.representation_attribute
              guards.each do |name, value|
                if minimum_children(root, name, []) < 1
                  raise Error, "profile #{@profile.id}: root #{signature(source)} does not require #{name}; exact discrimination is unsupported"
                end
                if clamp_attributes(root, name, value).zero?
                  raise Error, "profile #{@profile.id}: source excludes root #{name}=#{value.inspect}"
                end
              end
              root
            end
            components(@grammar).select { |n| rng?(n, "start") }.each(&:remove)
            start = new_element(@grammar, "start")
            if roots.size == 1
              start.add_child(roots.first)
            else
              choice = new_element(start, "choice")
              roots.each { |root| choice.add_child(root) }
            end
            reserve_namespaces_and_payload
            add_presentation_metadata if @representation == "presentation"
            { grammar: @grammar, roots: signatures }
          rescue Nokogiri::XML::SyntaxError => error
            raise Error, "profile #{@profile.id}: #{error.message}"
          end

          private

          def components(node)
            node.element_children.flat_map { |child| rng?(child, "div") ? components(child) : [child] }
          end

          def rng?(node, name)
            node && node.name == name && node.namespace&.href == NS
          end

          def children(node)
            node.element_children.select { |child| child.namespace&.href == NS }
          end

          def roots_in(node, seen = [])
            return [node] if rng?(node, "element")
            return [] if rng?(node, "notAllowed")
            if rng?(node, "ref")
              name = node["name"]
              raise Error, "recursive root reference #{name}" if seen.include?(name)

              return definitions(name).flat_map { |definition| roots_in(definition, seen + [name]) }
            end
            unless %w(start define div choice).include?(node.name)
              raise Error, "profile #{@profile.id}: unsupported start pattern #{node.name}"
            end
            children(node).flat_map { |child| roots_in(child, seen) }
          end

          def definitions(name)
            @definitions.fetch(name) { raise Error, "missing definition #{name}" }
          end

          def signature(node)
            name = node["name"]
            raise Error, "profile #{@profile.id}: root must have an explicit name" unless name

            if name.include?(":")
              prefix, name = name.split(":", 2)
              namespace = node.namespaces.fetch("xmlns:#{prefix}")
            else
              namespace = inherited(node, "ns").to_s
            end
            raise Error, "private validation namespace cannot be a document root" if namespace == PRIVATE_FACTS_NS

            { "name" => name, "namespace" => namespace }
          end

          def inherited(node, attribute)
            cursor = node
            while cursor&.element?
              return cursor[attribute] if cursor.key?(attribute)

              cursor = cursor.parent
            end
            nil
          end

          def inherit_context(target, source)
            %w(ns datatypeLibrary).each do |attribute|
              value = inherited(source, attribute)
              target[attribute] = value unless value.nil? || target.key?(attribute)
            end
            source.namespace_scopes.each do |ns|
              target.add_namespace_definition(ns.prefix, ns.href) unless target.namespace_scopes.any? { |own| own.prefix == ns.prefix }
            end
          end

          def guard_attribute?(node, name = nil)
            rng?(node, "attribute") && (name ? node["name"] == name : %w(flavor type).include?(node["name"]))
          end

          def contains_guard?(node, seen = [])
            return false if rng?(node, "element")
            return true if guard_attribute?(node)
            if rng?(node, "ref")
              name = node["name"]
              return false if seen.include?(name)

              return definitions(name).any? { |definition| contains_guard?(definition, seen + [name]) }
            end
            children(node).any? { |child| contains_guard?(child, seen) }
          end

          def clone_guard_refs(node)
            children(node).each do |child|
              next if rng?(child, "element")

              if rng?(child, "ref") && contains_guard?(child)
                original = child["name"]
                unless @aliases.key?(original)
                  name = "__shared_root_#{original}"
                  raise Error, "reserved definition collision #{name}" if @definitions.key?(name)

                  @aliases[original] = name
                  copies = definitions(original).map do |definition|
                    copy = definition.dup(1)
                    copy["name"] = name
                    @grammar.add_child(copy)
                    copy
                  end
                  @definitions[name] = copies
                  copies.each { |copy| clone_guard_refs(copy) }
                end
                child["name"] = @aliases.fetch(original)
              else
                clone_guard_refs(child)
              end
            end
          end

          def minimum_attribute(node, name, seen = [])
            return 1 if guard_attribute?(node, name)
            return 0 if rng?(node, "element")
            return 0 if %w(optional zeroOrMore notAllowed empty text data value attribute).include?(node.name)
            if rng?(node, "ref")
              key = node["name"]
              return 0 if seen.include?(key)

              values = definitions(key).map { |definition| minimum_children(definition, name, seen + [key]) }
              return definitions(key).any? { |definition| definition["combine"] == "choice" } ? values.min : values.sum
            end
            minimum_children(node, name, seen)
          end

          def minimum_children(node, name, seen)
            values = children(node).map { |child| minimum_attribute(child, name, seen) }
            node.name == "choice" ? (values.min || 0) : values.sum
          end

          def clamp_attributes(node, name, value, seen = [])
            children(node).sum do |child|
              next 0 if rng?(child, "element")

              if guard_attribute?(child, name)
                unless literal_allowed?(child, name, value)
                  child.replace(new_detached("notAllowed"))
                  next 0
                end
                child.children.remove
                literal = new_element(child, "value")
                literal["type"] = "string"
                literal["datatypeLibrary"] = XSD
                literal.content = value
                1
              elsif rng?(child, "ref")
                key = child["name"]
                next 0 if seen.include?(key)

                definitions(key).sum { |definition| clamp_attributes(definition, name, value, seen + [key]) }
              else
                clamp_attributes(child, name, value, seen)
              end
            end
          end

          def literal_allowed?(attribute, name, value)
            probe = @grammar.dup(1)
            components(probe).select { |node| rng?(node, "start") }.each(&:remove)
            start = new_element(probe, "start")
            root = new_element(start, "element")
            root["name"], root["ns"] = "probe", ""
            copy = attribute.dup(1)
            inherit_context(copy, attribute)
            copy["ns"] = ""
            root.add_child(copy)
            xml = Nokogiri::XML::Builder.new { |builder| builder.probe(name => value) }
            Nokogiri::XML::RelaxNG(probe.to_xml).validate(xml.doc).empty?
          end

          def reserve_namespaces_and_payload
            @grammar.xpath(".//r:element | .//r:attribute | .//r:name", XMLNS).each do |node|
              name = node["name"] || (node.name == "name" ? node.text : nil)
              next unless name
              next if node.ancestors.count { |ancestor| rng?(ancestor, "except") }.odd?

              namespace = name.include?(":") ? node.namespaces["xmlns:#{name.split(':').first}"] : inherited(node, "ns")
              raise Error, "source explicitly allows private validation content" if namespace == PRIVATE_FACTS_NS
              if node.name == "element" && name == PAYLOAD && roots_namespaces.include?(namespace.to_s)
                raise Error, "source already declares reserved presentation payload #{PAYLOAD}"
              end
            end
            @grammar.xpath(".//r:anyName | .//r:nsName", XMLNS).each do |node|
              next if node.ancestors.count { |ancestor| rng?(ancestor, "except") }.odd?

              if rng?(node, "nsName") && inherited(node, "ns") == PRIVATE_FACTS_NS
                raise Error, "source explicitly allows the private validation namespace"
              end
              forbidden = []
              if rng?(node, "anyName")
                item = new_detached("nsName")
                item["ns"] = PRIVATE_FACTS_NS
                forbidden << item
              end
              owner = node.ancestors.find { |ancestor| %w(element attribute).include?(ancestor.name) && ancestor.namespace&.href == NS }
              if owner&.name == "element"
                @root_namespaces ||= roots_namespaces
                @root_namespaces.each do |namespace|
                  next if rng?(node, "nsName") && inherited(node, "ns").to_s != namespace

                  item = new_detached("name")
                  item["ns"] = namespace
                  item.content = PAYLOAD
                  forbidden << item
                end
              end
              next if forbidden.empty?

              except = node.at_xpath("./r:except", XMLNS) || new_element(node, "except")
              previous = children(except).to_a
              previous.each(&:unlink)
              choice = new_element(except, "choice")
              (previous + forbidden).each { |item| choice.add_child(item) }
            end
          end

          def roots_namespaces
            components(@grammar).select { |node| rng?(node, "start") }
              .flat_map { |node| roots_in(node) }.map { |root| signature(root)["namespace"] }.uniq
          end

          def add_presentation_metadata
            @grammar.xpath(".//r:element[@name]", XMLNS).to_a.each do |node|
              next unless @metadata_parents.include?(node["name"])
              next unless roots_namespaces.include?(inherited(node, "ns").to_s)

              original = children(node).to_a
              original.each(&:unlink)
              interleave = new_element(node, "interleave")
              group = new_element(interleave, "group")
              original.each { |item| group.add_child(item) }
              optional = new_element(interleave, "optional")
              payload = new_element(optional, "element")
              payload["name"] = PAYLOAD
              METADATA_ATTRIBUTES.each do |name|
                attr = new_element(new_element(payload, "optional"), "attribute")
                attr["name"] = name
                new_element(attr, "text")
              end
              new_element(payload, "empty")
            end
          end

          def new_detached(name)
            node = Nokogiri::XML::Node.new(name, @document)
            node.namespace = @grammar.namespace
            node
          end

          def new_element(parent, name)
            node = Nokogiri::XML::Node.new(name, parent.document)
            node.namespace = parent.namespace
            parent.add_child(node)
            node
          end
        end
      end
    end
  end
end
