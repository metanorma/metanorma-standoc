# Shared grammar producer

`schemas/shared.rng` is one self-contained Relax NG artifact. The adjacent
`shared-profiles.json` declares declared profiles, root QNames, discriminator rules and the presentation metadata contract.
It is a producer candidate; existing validators and package selection are not
switched by requiring this module.

Load `metanorma/validate/universal_schema`, then construct
`Metanorma::Standoc::Validate::UniversalSchema::Validator` with the artifact XML
and parsed manifest. Call `validate(xml_or_nokogiri_document, flavor: "iec")`.
The result is an array of errors; an empty array means valid.
Existing validator instances can call `shared_schema_errors(document,
flavor: validation_flavor, representation: nil)` or `shared_schema_validate`
with the same arguments. The latter reports failures through registered
`STANDOC_7` messages with the location label `Document`. These methods lazily
load the shared artifact and preserve existing explicit custom-schema and
legacy fragment behavior. This XML interface
is separate from the existing declarative rule engine's DocumentRoot interface.

Each flavor keeps its original definition scope and content constraints in a
nested grammar. Exact root `flavor` and `type` values select modern branches.
GB, M3AAWG, MPFA, UN and VSD use their distinct existing root QNames without
inventing a flavor attribute. VSD also has no root type attribute: its caller
must supply `representation: "semantic"` or `"presentation"`. An explicitly
supplied representation must match the authored type wherever one exists.
Configured selection rejects other flavors before evaluating the shared RNG.
Different profiles may share a root QName only with distinct mandatory flavor
attributes; ambiguous discrimination is rejected during production.

The semantic branch preserves source content constraints and excludes the
reserved presentation metadata element and private ISO validation-facts
namespace. The presentation branch adds at most one `fmt-ladl-label-data` child
to the explicit model parent vocabulary, where that parent exists in the source
grammar. Its six attributes are optional strings; other attributes, text,
children and placement outside declared parents are forbidden. VSD's external
representation configuration additionally enforces this semantic restriction.
No schema wildcard is added for unsupported content. Existing foreign-content
wildcards retain their constraints, with reserved namespace/name exclusions.

`SourceBuilder#build(sources:)` regenerates the artifact from local pinned source
trees. Each source supplies `id`, `root`, `entry`, and optional discriminator flags.
Input diagnostics remain in memory; deployed configuration includes only runtime
profile selection and artifact integrity. Compilation preserves include overrides/combine,
namespace/datatype context and external grammar scope. Compaction removes only
foreign annotations, XML comments and formatting whitespace; literal
`value`, `param` and `name` text is retained.

The explicit migration `un-admonition-attributes-1` repairs UN's invalid
`AdmonitionAttr` include override by renaming it to `AdmonitionAttributes` and
lifting it outside the include. This interleaves the optional boolean
`unnumbered` extension with the original required type and optional base
attributes. Merely renaming the override would replace those constraints.
The compiler retains in-memory diagnostics; optional source tracking is not exported. The unmodified UN entry
is invalid and cannot serve as an acceptance oracle; the repaired baseline and
strict type/boolean negatives are tested separately.

The fixtures are small constructed full documents for the pinned grammars,
plus focused MathML/SVG and native Document-model examples. They establish
representative acceptance and rejection, not complete corpus parity. The
configuration covers the original 21 RNG entry grammars plus an explicit canonical ISO realization; active model-only validators
and downstream integration remain separate acceptance work. No source RNG is
removed and no flavor consumer is migrated by this producer.

The existing full-document processor normalizes SVG and formatted extension
content with `formattedstr_strip`, then serializes it with `to_xml` before
legacy schema validation. Consumers adopting the shared entrypoint at that
same boundary must pass `to_xml(formattedstr_strip(document.dup))`. The shared
entrypoint itself validates its supplied XML directly; it does not implicitly
strip content. The attribute-bearing SVG fixture proves both the old native
validator and shared entrypoint accept that explicitly normalized XML. Raw
SVG shape attributes remain subject to the pinned source grammar and can be
rejected. This is normalized processor parity, not raw SVG grammar conformance.

The explicit `iso` profile follows the genuine ISO SDK model: its root is
`metanorma` in the Standoc namespace with exact flavor `iso` and an explicit
semantic/presentation type. It inherits the common structure, while converter
version strings, generated section-title/table-cell IDs and duplicate extension flavor are
optional model metadata. Supplied extension flavor must still be `iso`.
Current-language and section visibility attributes are optional booleans. These
ISO model realization rules do not alter the existing converter profiles, and
ISO business restrictions remain the actual ISO rule registry's responsibility.
