# frozen_string_literal: true

module Metanorma
  module StandardDocument
    autoload :AnnotationContainer,
             "metanorma/standard_document/annotation_container"
    autoload :BlockAttributes, "metanorma/standard_document/block_attributes"
    autoload :BlockXmlMapping, "metanorma/standard_document/block_attributes"
    autoload :SectionXmlMapping, "metanorma/standard_document/block_attributes"
    autoload :PresentationAttributes,
             "metanorma/standard_document/block_attributes"
    autoload :OrderedContent, "metanorma/standard_document/block_attributes"
    autoload :Blocks, "metanorma/standard_document/blocks"
    autoload :Boilerplate, "metanorma/standard_document/boilerplate"
    autoload :Elements, "metanorma/standard_document/elements"
    autoload :Lists, "metanorma/standard_document/lists"
    autoload :Metadata, "metanorma/standard_document/metadata"
    autoload :Namespace, "metanorma/standard_document/namespace"
    autoload :Refs, "metanorma/standard_document/refs"
    autoload :Root, "metanorma/standard_document/root"
    autoload :RootAttributes, "metanorma/standard_document/root_attributes"
    autoload :Sections, "metanorma/standard_document/sections"
    autoload :StandardDocumentType,
             "metanorma/standard_document/standard_document_type"
    autoload :Terms, "metanorma/standard_document/terms"
  end
end
