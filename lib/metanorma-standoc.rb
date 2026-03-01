require "asciidoctor" unless defined? Asciidoctor::Converter
require_relative "isodoc/pdf_convert"
require_relative "metanorma/converter/converter"
require_relative "metanorma/converter/version"
require "asciidoctor/extensions"
require "metanorma"
require "vectory"

if defined? Metanorma::Registry
  require_relative "metanorma/standoc"
  Metanorma::Registry.instance.register(Metanorma::Standoc::Processor)
end
