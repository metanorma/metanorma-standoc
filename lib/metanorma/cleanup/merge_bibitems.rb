require "metanorma-utils"
require "relaton/bib"
require "yaml"

module Metanorma
  module Standoc
    class Cleanup
      class MergeBibitems
        Hash.include Metanorma::Utils::Hash
        Array.include Metanorma::Utils::Array

        class ::Array
          def blank?
            nil? || empty?
          end
        end

        class ::Hash
          def deep_merge(second)
            merger = proc { |_, v1, v2|
              if ::Hash === v1 && ::Hash === v2
                v1.merge(v2, &merger)
              elsif ::Array === v1 && ::Array === v2
                v2 # overwrite old with new
              elsif [:undefined].include?(v2)
                v1
              else
                v2
              end
            }
            merge(second.to_h, &merger)
          end
        end

        def initialize(old, new)
          @old = load_bibitem(old)
          @new = load_bibitem(new)
        end

        def load_bibitem(item)
          bib = Relaton::Bib::Bibitem.from_xml(item)
          YAML.safe_load(bib.to_yaml,
                         permitted_classes: [Date, Symbol],
                         symbolize_names: true)
        end

        def to_noko
          yaml_str = deep_stringify_keys(@old).to_yaml
          Nokogiri::XML(Relaton::Bib::Item.from_yaml(yaml_str).to_xml).root
        end

        def merge
          @old.delete(:formattedref)
          merge1(@old, @new)
          self
        end

        def merge1(old, new)
          # NOTE: 2.x YAML uses :docidentifier (not :docid) and :uri (not :link)
          # :note replaces :biblionote — TODO verify against actual 2.x YAML output
          %i(uri docidentifier date title series note).each do |k|
            merge_by_type(old, new, k, :type)
          end
          merge_extent(old, new)
          merge_contributor(old, new)
          %i(place version edition).each do |k|
            merge_simple(old, new, k)
          end
          merge_relations(old, new)
        end

        def merge_simple(old, new, field)
          (new[field].nil? || new[field].empty?) and return
          old[field] = new[field]
        end

        # ensure return value goes into extent[0]
        def merge_extent(old, new)
          old.dig(:extent, 0, :locality) and
            old[:extent] = [{ locality_stack: old[:extent] }]
          new.dig(:extent, 0, :locality) and
            new[:extent] = [{ locality_stack: new[:extent] }]
          ret = merge_by_type(old.dig(:extent, 0),
                              new.dig(:extent, 0), :locality_stack,
                              [:locality, 0, :type]) or return
          ret = ret.each_with_object([{ locality: [] }]) do |r, m|
            m[0][:locality] += r[:locality]
          end
          old[:extent] ||= []
          old[:extent][0] ||= {}
          old[:extent][0][:locality_stack] = ret
        end

        def merge_contributor(old, new)
          merge_by_type(old, new, :contributor, [:role, 0, :type])
        end

        def merge_relations(old, new)
          merge_by_type(old, new, :relation, :type, recurse: true)
        end

        # @old.field is an array, overwrite only those array elements
        # where @old.field[attribute] = @new.field[attribute]
        def merge_by_type(old, new, field, attributes, opt = {})
          new.nil? || new[field].nil? || new[field].empty? and return
          old.nil? and return new[field]
          !old[field].is_a?(::Array) || old[field].empty? and
            return old[field] = new[field]
          old[field] = merge_by_type1(old, new, field, attributes, opt)
        end

        def merge_by_type1(old, new, field, attributes, opt)
          old1 = array_to_hash(old[field], attributes)
          new1 = array_to_hash(new[field], attributes)
          out = opt[:recurse] ? old1.deep_merge(new1) : old1.merge(new1)
          out.each_value.with_object([]) do |v, m|
            v.each { |v1| m << v1 }
          end
        end

        def array_to_hash(array, attributes)
          array.each_with_object({}) do |k, m|
            m[k.dig(*Array(attributes))] ||= []
            m[k.dig(*Array(attributes))] << k
          end
        end

        private

        # Recursively stringify all symbol keys for YAML round-trip into
        # Relaton::Bib::Item.from_yaml. lutaml-model YAML expects string keys.
        def deep_stringify_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(k, v), h|
              h[k.to_s] = deep_stringify_keys(v)
            end
          when Array
            obj.map { |v| deep_stringify_keys(v) }
          else
            obj
          end
        end
      end
    end
  end
end
