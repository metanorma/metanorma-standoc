require "nokogiri"

module Nokogiri
  module XML
    class Builder
      class NodeBuilder
        def add_noko_elem(name, val, attrs = {})
          val and !val.empty? or return
          send name, **Metanorma::Utils::attr_code(attrs) do |n|
            n << val
          end
        end
      end
    end
  end
end
