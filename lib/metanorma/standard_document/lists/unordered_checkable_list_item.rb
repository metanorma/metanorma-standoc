# frozen_string_literal: true

module Metanorma
  module StandardDocument
    module Lists
      # List item for unordered lists for standards documents.
      class UnorderedCheckableListItem < Lutaml::Model::Serializable
        attribute :checkbox, :boolean
        attribute :checkedcheckbox, :boolean

        attribute :semx_id, :string
        attribute :original_id, :string
        attribute :displayorder, :integer

        xml do
          element "unordered-checkable-list-item"
          map_attribute "checkbox", to: :checkbox
          map_attribute "checkedcheckbox", to: :checkedcheckbox
          map_attribute "semx-id", to: :semx_id
          map_attribute "original-id", to: :original_id
          map_attribute "displayorder", to: :displayorder
        end
      end
    end
  end
end
