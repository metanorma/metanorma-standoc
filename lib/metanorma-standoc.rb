require "asciidoctor" unless defined? Asciidoctor::Converter
require_relative "isodoc/pdf_convert"
require_relative "metanorma/standoc/converter"
require_relative "metanorma/standoc/version"
require "asciidoctor/extensions"

if defined? Metanorma::Registry
  require_relative "metanorma/standoc"
  Metanorma::Registry.instance.register(Metanorma::Standoc::Processor)
end
