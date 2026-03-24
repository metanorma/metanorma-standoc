# Relaton 2.x Migration Guide

This document captures the breaking API changes between Relaton 1.x and Relaton 2.x,
and the required code changes for all Metanorma gems that depend on Relaton. It is
written incrementally as gems are migrated and new issues are discovered.

**Status:** Work in progress. Verified against `relaton-bib 2.0.0.pre.alpha.4` and
`relaton 2.0.0.pre.alpha.1`.

---

## Overview of Architectural Change

In Relaton 1.x, `relaton_bib` was a standalone gem providing:
- `RelatonBib::BibliographicItem` — the central bibliographic model class
- `RelatonBib::XMLParser` — XML parsing
- `RelatonBib::HashConverter` — Hash ↔ model conversion
- `RelatonBib::BibtexParser` — BibTeX parsing
- `RelatonBib.parse_yaml(...)` — YAML parsing helper

In Relaton 2.x:
- The gem is still named `relaton-bib` but its load path changed from `relaton_bib`
  to `relaton/bib`
- The codebase is rewritten using
  [lutaml-model](https://github.com/lutaml/lutaml-model) for serialization
- `RelatonBib::BibliographicItem` is replaced by `Relaton::Bib::ItemData` (data
  container) and `Relaton::Bib::Item`/`Bibitem`/`Bibdata` (serialization classes)
- The hash-based API (`to_hash`, `HashConverter`, `from_hash`) is **gone**

---

## Required File Changes

### 1. `require` statement

```ruby
# 1.x
require "relaton_bib"

# 2.x
require "relaton/bib"
```

This affects every gem file that directly requires the relaton-bib gem.

---

### 2. Parsing XML → Relaton object

```ruby
# 1.x — returns RelatonBib::BibliographicItem
ret = RelatonBib::XMLParser.from_xml(xml_string)

# 2.x — returns Relaton::Bib::ItemData (via lutaml-model)
ret = Relaton::Bib::Bibitem.from_xml(xml_string)
# or, for <bibdata> root element:
ret = Relaton::Bib::Bibdata.from_xml(xml_string)
```

> **Note:** `Relaton::Bib::Bibitem.from_xml` returns a `Bibitem` object which is
> a `Lutaml::Model::Serializable` subclass. Its `model` is `Relaton::Bib::ItemData`.
> You then call serialization methods on the item itself.

---

### 3. Converting a Relaton object back to XML

```ruby
# 1.x
xml_string = item.to_xml         # on RelatonBib::BibliographicItem

# 2.x — same method, but on ItemData
xml_string = item.to_xml         # on Relaton::Bib::ItemData
xml_string = item.to_xml(bibdata: true)  # render as <bibdata> root
```

---

### 4. Creating a BibliographicItem from a Hash (e.g., from YAML/AsciiDoc)

```ruby
# 1.x
xml = RelatonBib::BibliographicItem.from_hash(bib_hash).to_xml

# or equivalently:
h = RelatonBib::HashConverter.hash_to_bib(bib_hash)
xml = RelatonBib::BibliographicItem.new(**h).to_xml

# 2.x
h = Relaton::Bib::HashParserV1.hash_to_bib(bib_hash)
xml = Relaton::Bib::ItemData.new(**h).to_xml
```

> **Note:** `Relaton::Bib::HashParserV1` is the legacy hash parser. It accepts
> the same symbolized hash format as the 1.x `HashConverter` and returns a hash
> of constructor arguments for `ItemData.new`. The input hash must have **symbol
> keys** (the parser calls `symbolize` internally via `Marshal.load/dump`).

---

### 5. Parsing YAML

```ruby
# 1.x — relaton_bib provided its own YAML parser wrapper
r = RelatonBib.parse_yaml(yaml_string, [Date], symbolize_names: true)

# 2.x — use Ruby stdlib directly
r = YAML.safe_load(yaml_string, permitted_classes: [Date], symbolize_names: true)
```

> The stdlib `YAML.safe_load` uses keyword argument `permitted_classes:` (Ruby 3.1+),
> not a positional array argument.

---

### 6. Parsing BibTeX

```ruby
# 1.x — returns RelatonBib::BibliographicItem
item = RelatonBib::BibtexParser.from_bibtex(bibtex_string)

# 2.x — returns Relaton::Bib::ItemData
item = Relaton::Bib::Converter::Bibtex.to_item(bibtex_string)
```

---

### 7. `RequestError` exception class

```ruby
# 1.x
rescue RelatonBib::RequestError
if doc.is_a?(RelatonBib::RequestError)

# 2.x
rescue Relaton::RequestError
if doc.is_a?(Relaton::RequestError)
```

---

### 8. Fetching/rendering as XML string

```ruby
# 1.x — smart_render_xml accepted a BibliographicItem with to_xml
xml.respond_to?(:to_xml) or return nil
xml = Nokogiri::XML(xml.to_xml(lang: opts[:lang]))

# 2.x — ItemData.to_xml does NOT accept lang: kwarg at the top level.
# The lang option was used to select a language-specific title.
# In 2.x, pass it like:
xml.respond_to?(:to_xml) or return nil
xml = Nokogiri::XML(xml.to_xml)
```

> **TODO:** Verify whether the `lang:` option to `to_xml` is needed and whether
> `ItemData` provides an equivalent in 2.x. If it does, update this entry.

---

## Critical: `to_hash` — The YAML Round-Trip Pattern

### Background

In 1.x, `RelatonBib::BibliographicItem#to_hash` produced a symbolized hash
representation of the entire object tree, which could be manipulated (merged,
diffed, deep-copied) and then fed back into `HashConverter.hash_to_bib` →
`BibliographicItem.new`. This pattern was used in:

- `metanorma-standoc`: `MergeBibitems` class
- `metanorma` gem: collection-level bibitem merging
- `metanorma-cli`: hash-based bibitem manipulation

### 2.x: `to_hash` is Gone

`Relaton::Bib::ItemData` and `Relaton::Bib::Bibitem` do **not** provide a
`to_hash` method. `Lutaml::Model::Serializable` (0.7.7) does not provide one
either.

### Replacement: YAML Round-Trip

The recommended replacement is to round-trip through YAML, since YAML is a
first-class supported format in lutaml-model and is guaranteed to be maintained:

```ruby
# 1.x pattern:
def load_bibitem(xml_string)
  item = RelatonBib::XMLParser.from_xml(xml_string)
  item.to_hash.symbolize_all_keys   # produces symbolized hash
end

def save_bibitem(hash)
  out = RelatonBib::HashConverter.hash_to_bib(hash)
  Nokogiri::XML(RelatonBib::BibliographicItem.new(**out).to_xml).root
end

# 2.x pattern:
def load_bibitem(xml_string)
  item = Relaton::Bib::Bibitem.from_xml(xml_string)
  YAML.safe_load(item.to_yaml, permitted_classes: [Date, Symbol],
                 symbolize_names: true)
end

def save_bibitem(hash)
  yaml_str = deep_stringify_keys(hash).to_yaml
  item = Relaton::Bib::Item.from_yaml(yaml_str)
  Nokogiri::XML(item.to_xml).root
end

# Helper: recursively stringify symbol keys for YAML round-trip
def deep_stringify_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
  when Array
    obj.map { |v| deep_stringify_keys(v) }
  else
    obj
  end
end
```

### ⚠️ YAML Key Structure Differs from 1.x `to_hash`

**This is the primary instability risk.** The 2.x YAML structure produced by
lutaml-model is **not identical** to the 1.x `to_hash` output. Known differences
will be documented here as they are discovered during migration.

Differences confirmed so far:

| 1.x `to_hash` key | 2.x YAML key | Notes |
|---|---|---|
| `:docid` | `"docidentifier"` | The XML element name is used |
| `:link` | `"uri"` | The XML element name is used |
| `:biblionote` | `"note"` | TBC |
| `:date` | `"date"` | Same |
| `:title` | `"title"` | Same |
| `:contributor` | `"contributor"` | Same |
| `:extent` | `"extent"` | Same |
| `:series` | `"series"` | Same |
| `:relation` | `"relation"` | Same |

> **TODO:** Run `MergeBibitems` spec tests once isodoc and relaton-render are
> migrated, and update this table with all confirmed differences.

Any code that does **hash key access** on the old `to_hash` output (e.g.,
`old[:docid]`, `old[:link]`) must be updated to use the new string key names
from the 2.x YAML structure (or re-symbolized equivalents).

---

## Dependency Chain: What Needs Migration

The `require "relaton_bib"` issue cascades through the gem dependency chain.
All of the following gems need to be migrated **before** `metanorma-standoc`
tests can pass:

1. **`isodoc`** (currently 3.4.7) — contains `require "relaton_bib"` or
   transitively requires it. Needs migration before `metanorma-standoc` can load.

2. **`relaton-render`** (currently 1.0.4) — used by `isodoc` for rendering
   bibliographic references. Likely uses `RelatonBib::BibliographicItem` and
   `to_hash` for rendering.

3. **`metanorma-standoc`** — this gem, already partially migrated (see below).

4. **`metanorma`** — uses Relaton objects for collection-level processing,
   including hash manipulation of bibitems.

5. **`metanorma-cli`** — uses hash manipulation of bibitems.

---

## Status of `metanorma-standoc` Migration

The following files have been migrated:

| File | Status | Changes |
|---|---|---|
| `lib/metanorma/cleanup/asciibib.rb` | ✅ Done | `require`, `BibliographicItem.from_hash` → `HashParserV1` + `ItemData` |
| `lib/metanorma/cleanup/ref.rb` | ✅ Done | `require` only |
| `lib/metanorma/cleanup/bibdata.rb` | ✅ Done | `parse_yaml`, `HashConverter`, `BibliographicItem` |
| `lib/metanorma/converter/localbib.rb` | ✅ Done | `require`, `BibtexParser` → `Converter::Bibtex` |
| `lib/metanorma/converter/ref_queue.rb` | ✅ Done | `RequestError` (×2) |
| `spec/metanorma/refs_spec.rb` | ✅ Done | `RequestError`, `XMLParser.from_xml` (×6) |
| `lib/metanorma/cleanup/merge_bibitems.rb` | ⚠️ Pending | Needs `to_hash` → YAML round-trip + key name audit |

### `merge_bibitems.rb` — Pending

This file contains the entire hash-manipulation pattern. It needs:
1. `load_bibitem`: `RelatonBib::XMLParser.from_xml` + `to_hash` → YAML round-trip
2. `to_noko`: `HashConverter` + `BibliographicItem.new` → `Item.from_yaml` + `to_xml`
3. All hash key names in `merge1`, `merge_extent`, `merge_contributor`,
   `merge_relations`, `merge_by_type` updated from 1.x to 2.x YAML keys

---

## Full API Mapping Reference

| 1.x | 2.x | Notes |
|---|---|---|
| `require "relaton_bib"` | `require "relaton/bib"` | |
| `RelatonBib::BibliographicItem` | `Relaton::Bib::ItemData` | Data container class |
| `RelatonBib::BibliographicItem.new(**h)` | `Relaton::Bib::ItemData.new(**h)` | h from `HashParserV1.hash_to_bib` |
| `RelatonBib::BibliographicItem#to_xml` | `Relaton::Bib::ItemData#to_xml` | Same method name |
| `RelatonBib::BibliographicItem#to_xml(bibdata: true)` | `Relaton::Bib::ItemData#to_xml(bibdata: true)` | Same kwarg |
| `RelatonBib::BibliographicItem#to_hash` | *(none — see YAML round-trip)* | **Gone in 2.x** |
| `RelatonBib::BibliographicItem.from_hash(h)` | `Relaton::Bib::ItemData.new(**Relaton::Bib::HashParserV1.hash_to_bib(h))` | |
| `RelatonBib::XMLParser.from_xml(xml)` | `Relaton::Bib::Bibitem.from_xml(xml)` | Returns Bibitem, not ItemData |
| `RelatonBib::HashConverter.hash_to_bib(h)` | `Relaton::Bib::HashParserV1.hash_to_bib(h)` | Input: string or symbol keys |
| `RelatonBib::BibtexParser.from_bibtex(str)` | `Relaton::Bib::Converter::Bibtex.to_item(str)` | |
| `RelatonBib::RequestError` | `Relaton::RequestError` | |
| `RelatonBib.parse_yaml(str, [Date], symbolize_names: true)` | `YAML.safe_load(str, permitted_classes: [Date], symbolize_names: true)` | |
| `item.to_yaml` *(BibliographicItem)* | `item.to_yaml` *(ItemData)* | Same — via lutaml-model |
| `item.to_json` | `item.to_json` | Same — via lutaml-model |
| `item.to_bibtex` | `item.to_bibtex` | Same |
| `Relaton::Bib::Item.from_yaml(yaml_str)` | *(new in 2.x)* | Parse YAML string → ItemData |
| `Relaton::Bib::Item.from_json(json_str)` | *(new in 2.x)* | Parse JSON string → ItemData |

---

## Notes on `relaton-render` Migration

`relaton-render` (1.0.4) was written against `relaton-bib` 1.x. It likely uses:
- `item.to_hash` or direct attribute access on `BibliographicItem`
- `BibliographicItem` type checks (`item.is_a?(RelatonBib::BibliographicItem)`)

In 2.x, `ItemData` exposes the same **attribute accessor methods** as 1.x
`BibliographicItem` for most fields (`:title`, `:date`, `:docidentifier`,
`:contributor`, `:language`, `:script`, `:abstract`, `:series`, `:relation`,
`:extent`, `:source`, etc.), so code that accesses attributes directly (rather
than via hash) may work with minimal changes.

The major risk is any `to_hash`-based rendering logic.

---

## Notes on `metanorma` and `metanorma-cli` Migration

Both gems perform hash-level manipulation of Relaton bibitems for collection
processing. They will need the YAML round-trip pattern described above.

The key challenge is that field names change from 1.x `to_hash` to 2.x YAML:
- Use `Relaton::Bib::Bibitem.from_xml(xml).to_yaml` and inspect the output
  to map your 1.x field names to their 2.x equivalents
- Run `bundle exec ruby -e "require 'relaton/bib'; puts Relaton::Bib::Bibitem.from_xml('<bibitem>...</bibitem>').to_yaml"` to explore the structure

---

## Object Model API Changes

These sections document changes to the Ruby object model returned by
`Relaton::Bib::Bibitem.from_xml` / `Relaton::Bib::Item.from_yaml`. Discovered
during migration of `relaton-render`.

---

### 9. Collection attributes return `nil` when empty (not `[]`)

In Relaton 1.x, every collection attribute on `BibliographicItem` returned an
empty array `[]` when no elements were present. In Relaton 2.x (lutaml-model),
collection attributes return `nil` when no XML elements were present **unless**
the attribute was declared with `initialize_empty: true`.

Collections **known to return `nil`** when absent (confirmed from
`relaton-bib 2.0.0.pre.alpha.4`):

- `doc.relation`
- `doc.date`
- `doc.docidentifier`
- `doc.link` (URI links)
- `doc.place`
- `doc.series`
- `doc.extent`

Collections **always initialised to `[]`** (declared with `initialize_empty:
true`, safe to iterate without guard):

- `contributor.role`
- `person.name.forename`
- `organization.name`
- `organization.subdivision`
- `organization.identifier`

#### Required code change

Any code that calls enumerable methods (`.detect`, `.select`, `.any?`, `.each`,
`.map`, etc.) directly on these attributes must guard against `nil`:

```ruby
# 1.x — safe (always returns [])
doc.relation.detect { |r| r.type == "includedIn" }

# 2.x — raises NoMethodError if doc has no <relation> elements
doc.relation.detect { |r| r.type == "includedIn" }

# 2.x — correct patterns
doc.relation&.detect { |r| r.type == "includedIn" }
# or
Array(doc.relation).detect { |r| r.type == "includedIn" }
```

The `Array()` coercion pattern is preferred when an empty array is needed as the
fallback (e.g., in loops or `each_with_object`); `&.` is preferred when `nil` is
an acceptable return value.

---

### 10. `Contributor#entity` removed

In Relaton 1.x, `RelatonBib::ContributionInfo` (returned by `contributor.entity`)
provided a single polymorphic accessor for both person and organization:

```ruby
# 1.x
org = contributor.entity if contributor.entity.is_a?(RelatonBib::Organization)
person = contributor.entity if contributor.entity.is_a?(RelatonBib::Person)
```

In Relaton 2.x, `Relaton::Bib::Contributor` has **no `entity` method**. The two
contributor types are accessed via separate direct attributes:

```ruby
# 2.x
org = contributor.organization    # Relaton::Bib::Organization or nil
person = contributor.person       # Relaton::Bib::Person or nil
```

The is-a type test is no longer needed — just check for nil:

```ruby
# 2.x — full pattern
def extractname(contributor)
  org = contributor.organization
  person = contributor.person
  return { nonpersonal: extract_orgname(org) } if org
  return extract_personname(person) if person
  nil
end
```

Anywhere that previously accessed `c.entity.abbreviation` or `c.entity.name`
must be updated to `c.organization.abbreviation` / `c.organization.name`.

---

### 11. `Title` object structure flattened

In Relaton 1.x, document titles were `RelatonBib::TypedTitleString` objects,
each of which had a nested `.title` accessor returning a
`RelatonBib::LocalizedString`:

```ruby
# 1.x
x.title.language    # language of the title (Array of strings)
x.title.content     # the text content
x.type              # "main", "alt", etc.

# Select titles for a given language:
doc.title.select { |x| x.title.language&.include?(@lang) }
# Render a title:
content(t1.first.title)   # passes LocalizedString to content()
```

In Relaton 2.x, `Relaton::Bib::Title` **directly inherits** from
`LocalizedMarkedUpString` (which inherits from `LocalizedStringAttrs`). The
nested `.title` sub-object is **gone** — language, script, content and type are
all **direct attributes** on the title element itself:

```ruby
# 2.x
x.language    # String (single language tag, e.g. "en"), NOT an array
x.type        # "main", "alt", etc.
x.content     # the text content (String)

# Select titles for a given language:
doc.title.select { |x| x.language == @lang }
# Render a title:
content(t1.first)         # pass the Title object itself to content()
```

Note: `language` changed from an **Array** to a **single String** value.

---

### 12. `FullName#initials` renamed to `formatted_initials`

In Relaton 1.x, `RelatonBib::FullName` had an `initials` accessor for the
pre-formatted initials string:

```ruby
# 1.x
content(person.name.initials)
```

In Relaton 2.x, `FullNameType` uses `formatted_initials` instead:

```ruby
# 2.x
content(person.name.formatted_initials)
```

The attribute is a `LocalizedString` in both versions.

---

### 13. `Size` class: `size` collection renamed to `value`; value element uses `content`

In Relaton 1.x, `RelatonBib::Size` had a `size` collection of size value objects,
each with a `value` accessor for the text:

```ruby
# 1.x
x = doc.size
x.size.each_with_object({}) do |v, m|
  m[v.type] ||= []
  m[v.type] << v.value
end
```

In Relaton 2.x, the collection is named `value` and each element uses `content`:

```ruby
# 2.x
x = doc.size
x.value.each_with_object({}) do |v, m|
  m[v.type] ||= []
  m[v.type] << v.content
end
```

---

### 14. `doc.link` → `doc.source` (URI links)

In Relaton 1.x, URI links were accessed as `item.link` (returning an array of
`RelatonBib::TypedUri` objects with `.type`, `.content`, and `.language`).

In Relaton 2.x, the attribute is named `source` (because the XML element is
`<uri>` which maps to the `source` attribute in `Item`):

```ruby
# 1.x
doc.link.detect { |u| u.type == "citation" }

# 2.x
doc.source.detect { |u| u.type == "citation" }
```

Each `Uri` object has `.type`, `.content` (the URL string), and `.language`
(inherited from `LocalizedStringAttrs`). The interface is otherwise identical.

> **Note:** `ItemData#source` can also be called with a type argument:
> `doc.source("citation")` returns the URL content string directly (not the
> `Uri` object). When iterating over the collection, use `doc.source` (no args).

---

### 15. `formattedref` is a plain `String` in 2.x

In Relaton 1.x, `BibliographicItem#formattedref` returned a
`RelatonBib::FormattedString` object with a `.content` accessor:

```ruby
# 1.x
f = bib.formattedref
return f.content   # gets text from FormattedString object
```

In Relaton 2.x, `Item#formattedref` is declared as `attribute :formattedref, :string, raw: true`
— it returns a plain `String` (or `nil` when absent):

```ruby
# 2.x
f = bib.formattedref
return f   # already the string content
```

Any call to `.content` on a `formattedref` value must be removed. The `content`
helper used throughout relaton-render (which calls `node.content`) must also guard
against being passed a plain `String`:

```ruby
# Defensive content() helper for 2.x
def content(node)
  node.nil? and return node
  node.is_a?(String) and return node.strip   # handle plain strings
  node.content.is_a?(Array) and return node.content.map { |x| content(x) }
  node.content.strip
end
```

---

## Testing and Verification

After migrating a gem:

1. Run `bundle exec rspec` to catch any remaining `NameError`/`NoMethodError` from
   `RelatonBib::` constants
2. Search for any remaining legacy calls:
   ```
   grep -rn "relaton_bib\|RelatonBib::" lib/ spec/
   ```
3. For `to_hash` / YAML round-trip changes, run the bibitem merge/manipulation
   specs and compare XML output before and after migration
