require "metanorma-utils"

module Metanorma
  module Standoc
    module Cleanup
      class MergeBibitems
        Hash.include Metanorma::Utils::Hash
        Array.include Metanorma::Utils::Array

        class ::Array
          def blank?
            nil? || empty?
          end
        end

        def initialize(old, new)
          @old = load_bibitem(old)
          @new = load_bibitem(new)
        end

        def load_bibitem(item)
          ret = RelatonBib::XMLParser.from_xml(item)
          ret.to_hash.symbolize_all_keys
        end

        def to_noko
          out = RelatonBib::HashConverter.hash_to_bib(@old)
          Nokogiri::XML(RelatonBib::BibliographicItem.new(**out).to_xml).root
        end

        def merge
          @old.delete(:formattedref)
          merge1(@old, @new)
          self
        end

        def merge1(old, new)
          %i(link docid date title series biblionote).each do |k|
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
          new[field].blank? and return
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
                              %i[locality type])
          (ret && !old.dig(:extent, 0)) or return
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
          new.nil? || new[field].blank? and return
          old.nil? and return new[field]
          if !old[field].is_a?(::Array) || old[field].empty?
            return old[field] = new[field]
          end

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
      end
    end
  end
end
