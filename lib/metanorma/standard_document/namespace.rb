# frozen_string_literal: true

module Metanorma
  module StandardDocument
    class Namespace < Lutaml::Xml::Namespace
      uri "https://www.metanorma.org/ns/standoc"
      prefix_default "standoc"
      element_form_default :qualified
    end
  end
end
