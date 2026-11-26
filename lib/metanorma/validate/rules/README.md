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

## Cell-grid and term-state checks

These need whole-table or whole-document state, so they are code-backed: they
have no Schematron mapping and are listed as such on export. Findings may carry
computed values, read in `params` as `{value: key}` (valid only on checks that
yield several findings per context node).

`cell_grid` runs on a `table` context. `report: column_overflow` flags each
cell whose last column index (counted from zero, after rowspans and colspans are
applied) is greater than the column count taken from `columns` (`colgroup`: the
`col` elements; `row_cells`: the widest direct `tr` child), finding on the cell,
with value `columns`. `report: row_mismatch` flags the table when its rows, inside
`section` (`*`, `thead`, `tbody` or `tfoot`; default `*`), are not all the same
width. These mirror `Validate#table_validate` (STANDOC_4, STANDOC_5), including
its quirks: the colgroup and span rules both fire for a table matching both, and
the column test compares a zero-based index to the count, so a cell is reported
only when it is two or more columns past the declared width.

`duplicate_designation` runs on the document root. Terms selected by `terms` are
grouped by the text of each `designation` (nested `index` text ignored, `<domain>`
text from `prefix` prepended); each group of more than one is a finding on its
first term, with values `designation` and `locations` (anchors, comma-separated).
It mirrors `Validate#preferred_validate` (STANDOC_24).

`designation_outside_terms` runs on the document root. Designations selected by
`designations` that have no ancestor named by `terms` (default `terms`) are grouped
by their nearest ancestor among `containers`; each group is a finding on that
container, with value `designations` (hexadecimal-encoded text, comma-separated).
Designations with no container are skipped. It mirrors `Validate#termsect_validate`
(STANDOC_25).

## Document-state, file and option checks

Code-backed too (no Schematron mapping). A check whose `expand` takes a fourth
parameter receives the validator, for state it holds.

`concept_reference` runs on an `xref` inside a concept. It flags the xref when its
`target` is not among the anchors selected by `known`. Value `message` is
`<label> <refterm text> is pointing to <anchor>, which is not a term or symbol`, where the
anchor is that of the element whose `@id` equals the target (the target itself if there is
none). When the target is among the anchors selected by `subterm`, ". Did you mean to
point to a subterm?" is appended; otherwise the message ends in a newline, as the legacy
message does. STANDOC_23 has one rule for `concept` and one for `related`. An xref without
a target is flagged (legacy treats a missing anchor on a term as a match).

`file_missing` runs on an element with a `src` (or `attribute`). When the value is not a
URL or data URI and names no file, relative to the current directory or the document
directory (`Validate#localdir`), the finding is on the element's parent, with value `src`
(STANDOC_44).

`value_too_long` flags a context node whose `attribute` value is longer than the validator
option named by `limit` (`dataurimaxsize` only; zero disables), on the parent (STANDOC_46).

`duplicate_value` runs on the document root. Each element selected by `nodes` whose
`attribute` value an earlier selected element already holds is a finding on it, with values
`value` and `line` (the first holder's line number in the source, as Nokogiri reports it).
STANDOC_36 uses one rule for `@id` and one for `@anchor` (on elements that have an `@id`).
Legacy-only: the shadow rule runs on the Nokogiri document, so line numbers are those of
that parse.

Not migrated, because they call external engines or validate by content: STANDOC_45, 55-59
and 63 (png_conform, svg_conform), STANDOC_33 and other Plurimath checks.

## Text pattern check

`text_pattern` is code-backed (XPath 1.0 has no regular expressions, so it has no Schematron
mapping and is listed as code-backed on export). It runs on each context node (typically
`//p`) and searches the node's text, after removing descendants named in `exclude` (default
`stem` and `fmt-stem`: formulas are not prose). Arguments:

- `pattern`: a Ruby regular expression, or `words`: a list of words matched as whole words
  (exactly one of the two). `flags`: a string of `i`, `m`, `x`. Patterns have a two-second
  match timeout.
- `report`: `each` (default) gives one finding per distinct match, using the capture groups
  if the pattern has any (as `String#scan`); `once` gives one finding if anything matches.
- `message`: a template; each `%s` is replaced by the match. Values for params: `message`
  and `match`. The default message is the match.
- `language`: a list of codes. The check runs only if `bibdata/language`, or its primary
  subtag (`fr` for `fr-FR`), is listed; a document with no language counts as `en`.

The finding is on the context node.

```yaml
- id: iso.style.contractions
  code: ISO_77
  context: //p
  check: text_pattern
  args:
    words: ["don't", "isn't", "it's"]
    flags: i
    message: "style: contraction '%s' (use the full form)"
  params: [{value: message}]
```
