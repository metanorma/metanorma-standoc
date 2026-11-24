# Declarative validation rules (metanorma-standoc#1381)

## Rule format decision

Rules are written in YAML (schema `metanorma-validation-rules/1`) and are
interpreted, not compiled. A rule names an XPath `context`, an optional
`target`, and a `check` from an allowlist registered in Ruby. Rule files carry
no executable code. Severity and citation stay with the log registration of
the rule's `code`.

Schematron is an interchange format, not the source of truth. Rules whose
check has a `schematron` mapping (`required`, `forbidden`, `attribute_in`,
`xpath_assert`) can be exported with `Rules::Schematron.export`. Code-backed
checks (such as `empty_block`) have no XPath equivalent and are listed in
`Export#code_backed` instead of being approximated.

`Rules::Schematron.evaluate` runs an exported document (XPath 1.0, no `let`,
phases or abstract patterns) against a document, so the export can be checked
for agreement with the engine without an external Schematron processor.

Rules operate on the Metanorma document model through its semantic XML
projection (`DocumentProjection`). Flavors add files through
`validation_rule_files`; later layers replace rules by id, append new ones, or
remove them with `disable`.
