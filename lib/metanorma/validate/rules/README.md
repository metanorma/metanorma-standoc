# Declarative validation rules (metanorma-standoc#1381)

## Rule format decision

Rules are written in YAML (schema `metanorma-validation-rules/1`) and are
interpreted, not compiled. A rule names an XPath `context`, an optional
`target`, and a `check` from an allowlist registered in Ruby. Rule files carry
no executable code. Severity and citation stay with the log registration of
the rule's `code`.

Schematron is an interchange format, not the source of truth. Rules whose
check has a `schematron` mapping (`required`, `forbidden`, `attribute_in`,
`xpath_assert`, `nested`, `reference_exists`) can be exported with `Rules::Schematron.export`. Code-backed
checks (such as `empty_block`) have no XPath equivalent and are listed in
`Export#code_backed` instead of being approximated.

`Rules::Schematron.evaluate` runs an exported document (XPath 1.0, no `let`,
phases or abstract patterns) against a document, so the export can be checked
for agreement with the engine without an external Schematron processor.

Rules operate on the Metanorma document model through its semantic XML
projection (`DocumentProjection`). Flavors add files through
`validation_rule_files`; later layers replace rules by id, append new ones, or
remove them with `disable`.

Params are literals, `{node: name|text}`, `{attribute: NAME}` or
`{count: XPATH}`, the number of nodes the XPath selects from the context node.
Pure-XPath validations use `xpath_assert` with a test that holds when the node
is fine; `false()` flags every selected context node.

## Pair iteration and lookup checks

`nested` iterates (outer, inner) node pairs. The rule `context` selects the
outer nodes. Args: `inner` (required, element names searched among the
descendants of each outer node), `except` (optional, `outer/inner` name pairs
that are allowed) and `referenced_by` (optional, XPath expressions selecting
attribute nodes). Each remaining pair is one finding, raised on the inner
node, so one inner node nested in two outer nodes gives two findings. With
`referenced_by`, a pair is reported only when the inner node's `@anchor` is the
value of one of those attributes, and the finding is raised on the element
holding the last such reference (later expressions and later nodes win).
Params may use `{context: name|text|xml}` for the outer node and
`{related: name|text|xml}` for the inner node, besides the `{node: ...}` forms,
which now also accept `xml`. Ranges (`xref//location[@connective='to']`) are
not followed, so STANDOC_35 is covered for direct references only.

`reference_exists` is an in-document lookup. It flags a context node whose
`attribute` value is not the string value of any node selected by `known`, an
XPath over the whole document (for example `//*[@id]/@anchor`). A node
without the attribute is fine. STANDOC_38 uses one rule per anchor attribute.

Both export to Schematron and evaluate through `Schematron.evaluate`. Schematron
asserts once per context node: for `nested` that is once per outer node with
any offending pair, on the outer node, not once per pair on the inner or
referencing node. The engine remains the reference for exact findings.
