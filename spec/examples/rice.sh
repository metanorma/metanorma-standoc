asciidoctor rice.adoc
mv rice.html rice.preview.html
asciidoctor --trace -b standoc -r 'metanorma-standoc' rice.adoc

