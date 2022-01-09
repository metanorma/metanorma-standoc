warn "Please replace your references to Asciidoctor::Standoc with Metanorma::Standoc and your instances of require 'asciidoctor/standoc' with require 'metanorma/standoc'"

exit 127 if ENV['METANORMA_DEPRECATION_FAIL']

Asciidoctor::Standoc = Metanorma::Standoc unless defined? Asciidoctor::Standoc
