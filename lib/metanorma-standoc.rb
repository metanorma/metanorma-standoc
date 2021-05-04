require "asciidoctor" unless defined? Asciidoctor::Converter
require_relative "asciidoctor/standoc/converter"
require_relative "metanorma/standoc/version"
require "asciidoctor/extensions"

if defined? Metanorma
  require_relative "metanorma/standoc"
  Metanorma::Registry.instance.register(Metanorma::Standoc::Processor)
end
