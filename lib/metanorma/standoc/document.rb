# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    autoload :AnnotationContainer,
             "metanorma/standoc/document/annotation_container"
    autoload :BlockAttributes, "metanorma/standoc/document/block_attributes"
    autoload :BlockXmlMapping, "metanorma/standoc/document/block_attributes"
    autoload :SectionXmlMapping, "metanorma/standoc/document/block_attributes"
    autoload :PresentationAttributes,
             "metanorma/standoc/document/block_attributes"
    autoload :OrderedContent, "metanorma/standoc/document/block_attributes"
    autoload :Blocks, "metanorma/standoc/document/blocks"
    autoload :Boilerplate, "metanorma/standoc/document/boilerplate"
    autoload :Elements, "metanorma/standoc/document/elements"
    autoload :Lists, "metanorma/standoc/document/lists"
    autoload :Metadata, "metanorma/standoc/document/metadata"
    autoload :Namespace, "metanorma/standoc/document/namespace"
    autoload :Refs, "metanorma/standoc/document/refs"
    autoload :Root, "metanorma/standoc/document/root"
    autoload :RootAttributes, "metanorma/standoc/document/root_attributes"
    autoload :Sections, "metanorma/standoc/document/sections"
    autoload :StandardDocumentType,
             "metanorma/standoc/document/standard_document_type"
    autoload :Terms, "metanorma/standoc/document/terms"
  end
end
