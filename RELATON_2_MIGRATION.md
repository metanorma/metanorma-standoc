# Relaton 2.x Migration Guide

This document captures the breaking API changes between Relaton 1.x and Relaton 2.x,
and the required code changes for all Metanorma gems that depend on Relaton. It is
written incrementally as gems are migrated and new issues are discovered.

**Status:** Work in progress. Verified against `relaton-bib 2.0.0.pre.alpha.6` and
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

### 0. Flavor gem names: underscore → hyphen

In Relaton 1.x, the flavor-specific relaton gems used **underscores** in their
gem names (e.g. `relaton_iso`, `relaton_ietf`). In Relaton 2.x, all flavor gem
names use **hyphens** (e.g. `relaton-iso`, `relaton-ietf`).

This affects:

- **`Gemfile` / `Gemfile.lock`** — any `gem "relaton_xxx"` entry
- **`.gemspec` files** — any `spec.add_dependency "relaton_xxx"` declaration
- **`require` statements** — the load path also changed (see §1 below)

**Full mapping — gem name change:**

| 1.x gem name (underscore) | 2.x gem name (hyphen) |
|---|---|
| `relaton_bib` | `relaton-bib` |
| `relaton_bipm` | `relaton-bipm` |
| `relaton_bsi` | `relaton-bsi` |
| `relaton_ietf` | `relaton-ietf` |
| `relaton_iho` | `relaton-iho` |
| `relaton_itu` | `relaton-itu` |
| `relaton_iec` | `relaton-iec` |
| `relaton_iso` | `relaton-iso` |
| `relaton_nist` | `relaton-nist` |
| `relaton_ogc` | `relaton-ogc` |

**Example — `Gemfile` / gemspec update:**

```ruby
# 1.x — underscore
gem "relaton_iso", "~> 1.0"
spec.add_dependency "relaton_bib", "~> 1.0"

# 2.x — hyphen
gem "relaton-iso", "~> 2.0"
spec.add_dependency "relaton-bib", "~> 2.0"
```

> ⚠️ **Common mistake — do NOT use the gem name as the `require` path:**
> ```ruby
> require "relaton-iso"   # ← WRONG — LoadError: cannot load such file -- relaton-iso
> require "relaton/iso"   # ← CORRECT
> ```
> The gem name uses **hyphens** (`relaton-iso`); the Ruby `require` path uses
> **forward slashes** (`relaton/iso`). These are two completely independent naming
> conventions. Using the hyphenated gem name in a `require` statement will always
> raise `LoadError` because no file named `relaton-iso.rb` exists on the load path.

> **Note:** This is entirely separate from the `require` path change (§1).
> The gem name (used in `Gemfile` / gemspec) changed from underscore to hyphen;
> the `require` path changed from `relaton_xxx` to `relaton/xxx` (a slash-separated
> namespace). Both changes must be applied together when upgrading.

---

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
| `lib/metanorma/cleanup/merge_bibitems.rb` | ⚠️ Migrated — key names provisional | YAML round-trip done; hash key name audit pending (see §27) |

### `merge_bibitems.rb` — Migrated (pending key name verification)

The API calls have been migrated to the YAML round-trip pattern (§27).
The hash key names in `merge1` are provisional and must be verified against
live `bib.to_yaml` output once the `metanorma` gem (§26) is unblocked.

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
- `doc.link` (URI links — renamed `doc.source` in 2.x, see §14)
- `doc.place`
- `doc.series`
- `doc.extent`
- `doc.abstract`
- `doc.keyword`

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

#### ⚠️ Additional: scalar return when only one element is present

In some lutaml-model versions, a collection attribute declared as
`collection: true` (or `collection: (0..)`) can return the **element itself**
(not wrapped in an array) when exactly **one** element is present in the XML.
This means the attribute value can be:

- `nil` — no elements
- A single model object — exactly one element (not always; depends on version/declaration)
- An `Array` — more than one element

This was observed for `ItemData#title` in production: with one `<title>` element,
`bibdata.title` returned a single `Relaton::Bib::Title` object, causing
`bibdata.title.first` to raise `NoMethodError: undefined method 'first' for an
instance of Relaton::Bib::Title`.

**Always use `Array()` coercion** for collection attributes where this risk
exists — it handles nil, scalar, and array equally:

```ruby
# Safe against nil, scalar, and array
Array(doc.title).first&.content
Array(doc.docidentifier).first&.content
Array(doc.relation).detect { |r| r.type == "includedIn" }
```

This is preferable to `&.first` for attributes that can return a scalar.

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

### 16. `Docidentifier#id` → `#content`

In Relaton 1.x, `RelatonBib::DocumentIdentifier` had an `id` accessor for the
identifier string:

```ruby
# 1.x
docid.id       # e.g. "ISO 8601:2019"
```

In Relaton 2.x, `Relaton::Bib::Docidentifier` inherits from
`LocalizedMarkedUpString`, which uses `content` as the text accessor:

```ruby
# 2.x
docid.content  # e.g. "ISO 8601:2019"
```

The `type`, `scope`, and `primary` attributes remain unchanged. Anywhere that
called `id.id` or `out.map(&:id)` must be updated to `id.content` /
`out.map(&:content)`.

---

### 17. `Place` model restructured

In Relaton 1.x, `RelatonBib::Place` had a `name` accessor for a plain string
place name, and `region`/`country` sub-objects had a `name` accessor:

```ruby
# 1.x
place.name                          # e.g. "Geneva"
place.region.map(&:name)            # region names
place.country.map(&:name)           # country names
```

In Relaton 2.x, `Relaton::Bib::Place` has been restructured:

```ruby
# 2.x
place.formatted_place               # replaces place.name
place.city                          # city string
place.region.map(&:content)         # RegionType uses :content for text
place.country.map(&:content)        # RegionType uses :content for text
place.uri                           # optional Uri object
```

The fallback when no city/region/country is given should use
`place.formatted_place` instead of `place.name`. The `region` and `country`
collections are always initialised to `[]` (via `initialize_empty: true`).

---

### 18. `Date#on` → `Date#at`; date values are `StringDate::Value`, not `String`

In Relaton 1.x, `RelatonBib::BibItemDate` had `.on`, `.from`, `.to` accessors
returning plain Ruby Strings:

```ruby
# 1.x
date.on       # => "2024-01-01" (String or nil)
date.from     # => "2020" (String or nil)
date.to       # => "2025" (String or nil)
```

In Relaton 2.x, `Relaton::Bib::Date` has:

- `at` instead of `on` (XML `<on>` maps to `at` because `on` is a reserved word
  in YAML key-value serialisation)
- `from` and `to` remain, but all three return `StringDate::Value` objects, **not**
  plain Ruby Strings

```ruby
# 2.x
date.at     # => StringDate::Value (or nil) — replaces .on
date.from   # => StringDate::Value (or nil)
date.to     # => StringDate::Value (or nil)
```

`StringDate::Value` is a normalized ISO 8601 date string wrapper. It is **not**
a Ruby `Date` object but can be converted to one. Its internal `@value` is a
canonical date string produced by `Core::DateParser#parse_date(str: true)` —
one of `"YYYY"`, `"YYYY-MM"`, or `"YYYY-MM-DD"` depending on the input
precision. Key capabilities:

| Method / Operator | Behaviour |
|---|---|
| `.to_s` | Returns the normalized ISO 8601 string (delegated) |
| `.split` | Delegates `String#split` to the string value |
| `<=>` (Comparable) | Lexicographic comparison of strings — correct for ISO 8601 |
| `.to_date` | Parses `@value` → Ruby `Date` object (or `nil` on failure) |
| Any other `String` method | **Raises `NoMethodError`** — must call `.to_s` first |

So `StringDate::Value` **does** support date arithmetic, but only after conversion:
```ruby
date.at.to_date + 30   # add 30 days — requires .to_date
date.at.to_s           # get ISO string — for display/comparison
date.at > date.from    # works via Comparable (<=>)
```

Any code that calls `.sub(…)` on date values must first call `.to_s`:

```ruby
# 1.x
def datepick(date)
  date.nil? and return nil
  on = date.on
  from = date.from
  to = date.to
  on and return { on: on }
  from and return { from: from, to: to }
  nil
end

# 2.x — convert to String at the boundary
def datepick(date)
  date.nil? and return nil
  at = date.at
  from = date.from
  to = date.to
  at and return { on: at.to_s }
  from and return { from: from.to_s, to: to&.to_s }
  nil
end
```

By converting to String in `datepick`, all callers that use `.sub` or other
String methods continue to work without further changes.

#### Year extraction — `date.on(:year)` pattern

Some 1.x code called `date.on(:year)` to obtain the 4-digit year as a string.
In Relaton 2.x `Date#on` is gone entirely, so this must be replaced by calling
`Date#at` (which returns a `StringDate::Value`) and then slicing the year prefix:

```ruby
# 1.x
date.on(:year)          # => "2024" (String)

# 2.x
date.at&.to_s&.[](0, 4) # => "2024" (String)
# or equivalently:
date.at&.to_s&.split("-")&.first
```

When the date collection itself may be `nil` (§9), guard with `Array()`:

```ruby
# safe year extraction from an ItemData date collection
def date_year(date_obj)
  date_obj&.at&.to_s&.[](0, 4)
end

year = date_year(Array(item.date).first)
```

> **Note (`alpha.6` change):** In `relaton-bib 2.0.0.pre.alpha.6`, the `StringDate`
> class was refactored from `Lutaml::Model::Serializable` (with a nested
> `attribute :value, StringDate::Value`) to `Lutaml::Model::Type::Value` (a plain
> type converter). Its `cast(str)` method returns `StringDate::Value` directly.
> As a result, `date.at`, `date.from`, and `date.to` now return `StringDate::Value`
> **directly** (rather than a `StringDate` Serializable wrapper). The public
> interface — `.to_s`, `.split`, `<=>`, `.to_date` — is unchanged. Code that was
> previously calling `.value.to_s` on a `StringDate` Serializable must be updated
> to call `.to_s` directly on the `StringDate::Value`.

---

### 19. `Status::Stage#value` → `#content`

In Relaton 1.x, `RelatonBib::DocumentStatus::Stage` had a `value` accessor for
the stage text:

```ruby
# 1.x
doc.status.stage.value   # => "draft", "published", etc.
```

In Relaton 2.x, `Relaton::Bib::Status::Stage` uses `content` (mapped with
`map_content to: :content` in lutaml-model):

```ruby
# 2.x
doc.status.stage.content   # => "draft", "published", etc.
```

The `abbreviation` attribute on `Stage` remains unchanged.

---

### 20. `Series#title` is now a collection

In Relaton 1.x, `RelatonBib::Series#title` returned a single
`RelatonBib::LocalizedString`:

```ruby
# 1.x
series.title        # => LocalizedString — call content() on it directly
content(series.title)
```

In Relaton 2.x, `Relaton::Bib::Series#title` is declared as
`attribute :title, Title, collection: (1..)` — a required collection of one or
more `Title` objects, identical in structure to `Item#title`.

```ruby
# 2.x — series.title returns an Array of Title objects
content(series.title)   # NoMethodError: undefined method 'content' for Array
```

The fix is to use the same language-selection pattern as `title(doc)`:

```ruby
# 2.x — correct
def series_title(series, _doc)
  series.nil? and return nil
  t = Array(series.title).select { |x| x.language == @lang }
  t.empty? and t = Array(series.title)
  t1 = t.select { |x| x.type == "main" }
  t1.empty? and t1 = t
  t1.first.nil? and return nil
  esc(content(t1.first))
end
```

Note: `series.formattedref` remains `attribute :formattedref, :string, raw: true`
(a plain String), and `series.abbreviation` remains a single `LocalizedString` —
neither is a collection.

---

### 21. `Series#from`/`Series#to` — granularity-preserving `StringDate`

> ✅ **Fixed in `relaton-bib 2.0.0.pre.alpha.6`** — `Series#from` and
> `Series#to` are now declared as `attribute :from, StringDate` /
> `attribute :to, StringDate`, consistent with how `Date#at`, `Date#from`,
> and `Date#to` are declared.

In `relaton-bib 2.0.0.pre.alpha.4` and earlier, `Series#from` and `Series#to`
were declared as `attribute :from, :date` / `attribute :to, :date` (plain Ruby
`Date` type). This caused **silent data loss**: year-only `"2020"` or
year-month `"2020-06"` values could not be parsed as Ruby `Date` objects and
returned `nil`.

From `2.0.0.pre.alpha.6`, `series.from` and `series.to` return
`StringDate::Value` objects (see §18 for details), preserving the original
ISO 8601 granularity. The `series_dates` rendering method uses string
interpolation (`"#{f}–#{t}"`) which calls `StringDate::Value#to_s`, delegating
to `@value.to_s` — the granularity-preserving canonical string:

```ruby
# 2.0.0.pre.alpha.6+
def series_dates(series, _doc)
  f = series.from
  t = series.to
  f || t or return nil
  "#{f}–#{t}"   # => "2020–2022", "2020-06–2022-03", etc.
end
```

**Minimum version required:** downstream gems depending on correct series date
rendering must declare `>= 2.0.0.pre.alpha.6`.

---

### 22. `<place>` flat text no longer supported — must use `<formattedPlace>` or structured child elements

In Relaton 1.x, the publication place was a simple text element:

```xml
<!-- 1.x relaton XML -->
<place>New York, NY</place>
<place>Cambridge, UK</place>
```

`RelatonBib::Place#name` returned this flat text string directly.

In Relaton 2.x, `Relaton::Bib::Place` has no `map_content` — the plain text
body of `<place>` is **silently ignored**. Instead, place must be expressed using
child elements:

```xml
<!-- 2.x — formatted place (single string, replaces the 1.x flat format) -->
<place><formattedPlace>New York, NY</formattedPlace></place>

<!-- 2.x — structured place (broken out by city, region, country) -->
<place>
  <city>New York</city>
  <region>NY</region>
</place>
<place>
  <city>Cambridge</city>
  <country>UK</country>
</place>
```

The `Place` model attributes:
- `formatted_place` — replaces the old `name` accessor
- `city` — city string
- `region` — `RegionType` collection (`initialize_empty: true`, always `[]`)
- `country` — `RegionType` collection (`initialize_empty: true`, always `[]`)
- `uri` — optional `Uri`

Both formats must be supported by `place1`:

```ruby
# 2.x — handles both formattedPlace and city/region/country
def place1(place)
  c = place.city
  r = place.region
  n = place.country
  c.nil? && r.empty? && n.empty? and return place.formatted_place
  [c, *r.map(&:content), *n.map(&:content)].compact.join(", ")
end
```

> ⚠️ **TODO for `metanorma-standoc`:** The `pubplace` / place XML generation in
> `metanorma-standoc` currently emits the old flat-text `<place>` format. This
> needs to be updated to emit `<place><formattedPlace>...</formattedPlace></place>`
> for the new format. Deferred until the standoc migration resumes.

---

### 23. `<status>` XML format: flat text → `<stage>` child element

In Relaton 1.x, the document status was serialised as a flat text element:

```xml
<!-- 1.x -->
<status>valid</status>
```

`RelatonBib::BibItemDate#status` returned the text content as a plain String.

In Relaton 2.x, `Status` maps only child elements (`<stage>`, `<substage>`,
`<iteration>`). There is no `map_content` on `Status` — the flat text body is
**silently ignored**. The correct format is:

```xml
<!-- 2.x -->
<status>
  <stage>valid</stage>
</status>
<status>
  <stage abbreviation="FDIS">40.00</stage>
  <substage>20</substage>
  <iteration>2</iteration>
</status>
```

Accessing the stage value:

```ruby
# 1.x
doc.status   # => "valid" (String)

# 2.x
doc.status.stage.content          # => "valid"
doc.status.stage.abbreviation     # => "FDIS" (or nil)
doc.status.substage&.content      # => "20" (or nil)
doc.status.iteration              # => "2" (or nil)
```

**Impact on downstream gems:** Any XML fixtures (test or production) that use
the flat `<status>text</status>` format must be updated to
`<status><stage>text</stage></status>`. Otherwise `doc.status.stage` returns
nil and all status-dependent rendering (draft label, status label) silently
produces empty output.

---

### 24. `Series#place` returns `Place` object, not `String`

In Relaton 1.x, `RelatonBib::Series#place` returned a plain `String`:

```ruby
# 1.x
series.place   # => "Paris"
```

In Relaton 2.x, `Relaton::Bib::Series#place` is declared as
`attribute :place, Place` and returns a `Place` object (or nil):

```ruby
# 2.x
series.place                          # => Relaton::Bib::Place object (or nil)
series.place.formatted_place          # => "Paris"
```

Any rendering code that calls `esc(series.place)` or uses `series.place`
directly as a string will fail (either via `NoMethodError` from the `esc`
helper's `.empty?` check, or via garbled object-to-string conversion).

**Fix:** Extract the string from the `Place` object using the same `place1`
helper used for publication places:

```ruby
# 2.x — correct
def series_place(series, _doc)
  p = series.place or return nil
  place1(p)   # returns formatted_place, or city/region/country joined string
end
```

---

### 25. `Extent` with `choice` — `locality_stack` vs `locality`

In Relaton 1.x, `<extent>` could contain a mix of `<locality>` and
`<localityStack>` elements, all accessible via a single `localities` accessor.

In Relaton 2.x, `Relaton::Bib::Extent` uses a **`choice` constraint**: each
`Extent` instance has EITHER direct `<locality>` children OR `<localityStack>`
children — not both. The two branches are separate attributes:

```ruby
# 2.x
e.locality         # Array of Locality — populated when <locality> children present
e.locality_stack   # Array of LocalityStack — populated when <localityStack> children present
```

Both are initialised to `[]` (`initialize_empty: true`). When
`<localityStack>` children are present, `e.locality` is an **empty array**
and `e.locality_stack` is populated. Code that iterates only over `e.locality`
will silently skip the extent data when `<localityStack>` is used.

**Fix:** Add a `locality_stack` fallback branch:

```ruby
# 2.x — handles both locality and localityStack forms
def extent(doc)
  Array(doc.extent).each_with_object([]) do |e, acc|
    case e
    when Relaton::Bib::Extent, Relaton::Bib::LocalityStack
      if e.locality.any?
        # Direct <locality> children — group into a single hash
        a = e.locality.each_with_object([]) do |e1, m|
          m.empty? and m << {}
          m[-1].merge!(extent1(Array(e1)))
        end
        acc << a
      else
        # <localityStack> children — each stack becomes a separate entry
        Array(e.locality_stack).each do |stack|
          a = stack.locality.each_with_object([{}]) do |e1, m|
            m[-1].merge!(extent1(Array(e1)))
          end
          acc << a
        end
      end
    when Relaton::Bib::Locality
      acc << extent1(Array(e))
    end
  end
end
```

Both input forms produce the same grouping: all localities within a stack (or
within the `<extent>`) are merged into a single hash of
`{volume: ..., issue: ..., page: ...}`.

---

### 26. `metanorma` gem — `bibdata.rb` lutaml-model `model` directive ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch. The `metanorma` gem had
> a **hard load-time dependency on `RelatonBib`** via the lutaml-model `model`
> directive in `collection/config/bibdata.rb`. Changed to `Relaton::Bib::ItemData`.

**Location:** `lib/metanorma/collection/config/bibdata.rb`

**The load-time error:**

```
NameError: uninitialized constant RelatonBib
# ./lib/metanorma/collection/config/bibdata.rb:8:in '<class:Bibdata>'
```

The load chain was:

```
metanorma.rb:16
  → collection/collection.rb:5
    → collection/config/config.rb:5
      → collection/config/bibdata.rb:7
          model ::RelatonBib::BibliographicItem   ← NameError at class load time
```

**`Bibdata`** is a lutaml-model serializer class (`< Lutaml::Model::Serializable`)
with **no XML/YAML mapping defined** — all serialization is handled by custom
converters in `converters.rb`. The `model` directive is solely a type declaration
used by lutaml-model's type system.

**Before:**

```ruby
class Bibdata < ::Lutaml::Model::Serializable
  model ::RelatonBib::BibliographicItem
end
```

**After:**

```ruby
class Bibdata < ::Lutaml::Model::Serializable
  model ::Relaton::Bib::ItemData
end
```

**Downstream gem impact:** Any gem that calls `require "metanorma"` (including
`metanorma-standoc`) fails to load until this change is in place. A
`Gemfile.devel` entry is required for local development:

```ruby
# Gemfile.devel
gem "metanorma", git: "https://github.com/metanorma/metanorma",
                 branch: "fix/relaton-2.0"
```

---

### 27. `merge_bibitems.rb` — YAML round-trip migration *(tentative: key names unverified)*

> **Status:** The `load_bibitem` / `to_noko` methods have been migrated to the
> YAML round-trip pattern. The hash key name mapping in `merge1` is provisional —
> the actual 2.x YAML key names must be verified against live output once the
> `metanorma` gem dependency is resolved and tests can run.

**Before (1.x `to_hash` pattern):**

```ruby
require "metanorma-utils"

def load_bibitem(item)
  ret = RelatonBib::XMLParser.from_xml(item)
  ret.to_hash.symbolize_all_keys   # produces symbolized 1.x hash
end

def to_noko
  out = RelatonBib::HashConverter.hash_to_bib(@old)
  Nokogiri::XML(RelatonBib::BibliographicItem.new(**out).to_xml).root
end

def merge1(old, new)
  %i(link docid date title series biblionote).each do |k|
    merge_by_type(old, new, k, :type)
  end
  # ...
end
```

**After (2.x YAML round-trip pattern):**

```ruby
require "metanorma-utils"
require "relaton/bib"
require "yaml"

def load_bibitem(item)
  bib = Relaton::Bib::Bibitem.from_xml(item)
  YAML.safe_load(bib.to_yaml,
                 permitted_classes: [Date, Symbol],
                 symbolize_names: true)
end

def to_noko
  yaml_str = deep_stringify_keys(@old).to_yaml
  Nokogiri::XML(Relaton::Bib::Item.from_yaml(yaml_str).to_xml).root
end

def merge1(old, new)
  # 2.x YAML key changes: :link → :uri, :docid → :docidentifier, :biblionote → :note
  %i(uri docidentifier date title series note).each do |k|
    merge_by_type(old, new, k, :type)
  end
  # ...
end

private

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

**Key name changes confirmed/provisional (verify with live YAML output):**

| 1.x `to_hash` symbol key | 2.x YAML symbol key | Status |
|---|---|---|
| `:docid` | `:docidentifier` | ✅ Confirmed (maps to XML element `<docidentifier>`) |
| `:link` | `:uri` | ✅ Confirmed (maps to XML element `<uri>`) |
| `:biblionote` | `:note` | ⚠️ Provisional — verify |
| `:date` | `:date` | Same |
| `:title` | `:title` | Same |
| `:contributor` | `:contributor` | Same |
| `:extent` | `:extent` | Same |
| `:series` | `:series` | Same |
| `:relation` | `:relation` | Same |
| `:place` | `:place` | Same — but value structure changed (see §22) |
| `:version` | `:version` | Provisional |
| `:edition` | `:edition` | Same |

> **TODO:** Once the `metanorma` dep is unblocked, run the `MergeBibitems`
> specs, print `bib.to_yaml` from `load_bibitem`, and verify every key in
> `merge1`, `merge_extent`, `merge_contributor`, and `array_to_hash`.

---

### 28. `metanorma` gem — `document.rb` flavor-specific XML parsers ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch. All nine flavor-specific
> XML parser class references (`RelatonXxx::XMLParser`) and their `require` paths
> have been updated to 2.x equivalents. Subsequently refined (§34) to always use
> `Relaton::Bib::Bibitem` for `<bibitem>` elements regardless of flavor.

**Location:** `lib/metanorma/collection/document/document.rb`

In 2.x, the relaton flavor gems:
1. Changed their `require` path from `require "relaton_xxx"` to `require "relaton/xxx"`
2. Dropped `XMLParser` — replaced by the `Bibitem` serializer class in the
   `Relaton::Xxx::` namespace (which provides `.from_xml`)
3. Dropped the `RelatonXxx` namespace entirely — all use `Relaton::Xxx`

**Full mapping (all 9 flavors + generic fallback):**

| 1.x require | 2.x require |
|---|---|
| `require "relaton_bipm"` | `require "relaton/bipm"` |
| `require "relaton_bsi"` | `require "relaton/bsi"` |
| `require "relaton_ietf"` | `require "relaton/ietf"` |
| `require "relaton_iho"` | `require "relaton/iho"` |
| `require "relaton_itu"` | `require "relaton/itu"` |
| `require "relaton_iec"` | `require "relaton/iec"` |
| `require "relaton_iso"` | `require "relaton/iso"` |
| `require "relaton_nist"` | `require "relaton/nist"` |
| `require "relaton_ogc"` | `require "relaton/ogc"` |

| 1.x class | 2.x class |
|---|---|
| `::RelatonBipm::XMLParser` | `::Relaton::Bipm::Bibitem` |
| `::RelatonBsi::XMLParser` | `::Relaton::Bsi::Bibitem` |
| `::RelatonIetf::XMLParser` | `::Relaton::Ietf::Bibitem` |
| `::RelatonIho::XMLParser` | `::Relaton::Iho::Bibitem` |
| `::RelatonItu::XMLParser` | `::Relaton::Itu::Bibitem` |
| `::RelatonIec::XMLParser` | `::Relaton::Iec::Bibitem` |
| `::RelatonIsoBib::XMLParser` | `::Relaton::Iso::Bibitem` |
| `::RelatonNist::XMLParser` | `::Relaton::Nist::Bibitem` |
| `::RelatonOgc::XMLParser` | `::Relaton::Ogc::Bibitem` |
| `::RelatonBib::XMLParser` (fallback) | `::Relaton::Bib::Bibitem` |

**Bibliography entry-point class namespace change:**

The bibliography fetch classes (used in RSpec mocks and production code that calls
the Relaton fetch API directly) also changed namespace from `RelatonXxx::` to
`Relaton::Xxx::`, **and the redundant flavor prefix was dropped from the class name**:

| 1.x class | 2.x class |
|---|---|
| `RelatonIsoBib::XMLParser` | `Relaton::Bib::Bibitem` (generic) or `Relaton::Iso::Bibitem` (flavor) |
| `RelatonIso::IsoBibliography` | `Relaton::Iso::Bibliography` |
| `RelatonNist::NistBibliography` | `Relaton::Nist::Bibliography` |
| `RelatonIetf::IetfBibliography` | `Relaton::Ietf::Bibliography` |
| `RelatonIec::IecBibliography` | `Relaton::Iec::Bibliography` |

> ⚠️ **The flavor-specific prefix is dropped:** `IsoBibliography` → `Bibliography`,
> `IetfBibliography` → `Bibliography`, etc. The class is always named `Bibliography`
> within its namespace. Using the old names (e.g. `Relaton::Iso::IsoBibliography`)
> raises `NameError: uninitialized constant`.

These appear in RSpec `expect(...).to receive(:get)` / `receive(:search)` mocks.
Update all mock targets when migrating spec files.

Note that for ISO the old class was in the `RelatonIsoBib` namespace but the
new class is `Relaton::Iso::Bibitem` (the namespace mirrors the require path).

The `defined?` guard in each `when` branch must also be updated:

```ruby
# 1.x
when "iso"
  require "relaton_iso" unless defined?(::RelatonIsoBib::XMLParser)
  ::RelatonIsoBib::XMLParser

# 2.x
when "iso"
  require "relaton/iso" unless defined?(::Relaton::Iso::Bibitem)
  ::Relaton::Iso::Bibitem
```

The `rescue LoadError` fallback warn message is also updated:

```ruby
# 1.x
warn "... Falling back to RelatonBib::XMLParser"
::RelatonBib::XMLParser

# 2.x
warn "... Falling back to Relaton::Bib::Bibitem"
::Relaton::Bib::Bibitem
```

**`type` method — `Docidentifier#id` → `#content` (§16):**

```ruby
# 1.x
def type
  first = @bibitem.docidentifier.first
  @type ||= (first&.type&.downcase ||
             first&.id&.match(/^[^\s]+/)&.to_s)&.downcase ||
    "standoc"
end

# 2.x — guard nil collection (§9), use .content (§16)
def type
  first = @bibitem.docidentifier&.first
  @type ||= (first&.type&.downcase ||
             first&.content&.match(/^[^\s]+/)&.to_s)&.downcase ||
    "standoc"
end
```

---

### 29. `metanorma` gem — `converters.rb` `to_hash` → YAML round-trip ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch.

**Location:** `lib/metanorma/collection/config/converters.rb`

**`bibdata_to_yaml` — `to_hash` is gone in 2.x:**

```ruby
# 1.x
def bibdata_to_yaml(model, doc)
  doc["bibdata"] = model.bibdata&.to_hash
end

# 2.x — YAML round-trip (ItemData#to_yaml is provided by lutaml-model)
def bibdata_to_yaml(model, doc)
  return unless model.bibdata
  doc["bibdata"] = YAML.safe_load(model.bibdata.to_yaml,
                                  permitted_classes: [Date, Symbol])
end
```

`model.bibdata` is a `Relaton::Bib::ItemData` instance (set by the custom
`bibdata_from_yaml` / `bibdata_from_xml` converters). `ItemData#to_yaml` is
provided by lutaml-model and returns a YAML string; `YAML.safe_load` converts
it back to a Ruby hash for embedding in the collection YAML document.

**`bibdata_to_xml` — `date_format:` kwarg retained:**

```ruby
# retained from 1.x — kwarg left in place pending 2.x support confirmation
def bibdata_to_xml(model, parent, doc)
  b = model.bibdata or return
  elem = b.to_xml(bibdata: true, date_format: :full)
  doc.add_element(parent, elem)
end
```

> **TODO:** Verify whether `Relaton::Bib::ItemData#to_xml` accepts the
> `date_format:` keyword argument in 2.x. If not, request it be added back.

**`bibdata_from_yaml` — hybrid 1.x/2.x format detection ✅ Fixed:**

The `bibdata:` section of a collection YAML can be in either the **1.x Relaton
YAML format** (using `docid:`, `link:`, `biblionote:` etc.) or the **2.x
lutaml-model YAML format** (using `docidentifier:`, `uri:`, `note:` etc.).
Backward compatibility with existing collection YAML files is a hard requirement,
so the format must be auto-detected at parse time.

**Format detection strategy** — presence of any 1.x-only key (`docid:`, `link:`,
`biblionote:`) at any nesting level is diagnostic:

```ruby
# Keys present only in 1.x YAML format — unambiguously absent in 2.x
V1_BIBDATA_KEYS = %w[docid link biblionote].freeze

def bibdata_yaml_v1_format?(obj)
  case obj
  when Hash
    return true if (obj.keys.map(&:to_s) & V1_BIBDATA_KEYS).any?
    obj.values.any? { |v| bibdata_yaml_v1_format?(v) }
  when Array
    obj.any? { |v| bibdata_yaml_v1_format?(v) }
  else
    false
  end
end
```

The check is recursive so that 1.x-format entries nested inside `relation:` or
`contributor:` values are also detected. `.map(&:to_s)` on keys handles both
string-keyed and symbol-keyed hashes.

**Full `bibdata_from_yaml` implementation:**

```ruby
# 1.x
require "relaton-cli"

def bibdata_from_yaml(model, value)
  (value and !value.empty?) or return
  force_primary_docidentifier_yaml(value)
  model.bibdata = Relaton::Cli::YAMLConvertor.convert_single_file(value)
end

# 2.x — hybrid detection; HashParserV1 bridge for legacy 1.x format
require "relaton/bib"
# Note: HashParserV1 is NOT auto-loaded by require "relaton/bib" in alpha.6
require "relaton/bib/hash_parser_v1"

# Keys present only in 1.x YAML format — unambiguously absent in 2.x
V1_BIBDATA_KEYS = %w[docid link biblionote].freeze

def bibdata_from_yaml(model, value)
  (value and !value.empty?) or return
  if value.is_a?(String)
    # value is a file path — read and parse the YAML file (may be 1.x or 2.x format)
    value = YAML.safe_load_file(value, permitted_classes: [Date, Symbol])
  end
  force_primary_docidentifier_yaml(value)
  model.bibdata = if bibdata_yaml_v1_format?(value)
                   # 1.x YAML format (docid:/link:/biblionote: present) —
                   # bridge via HashParserV1 for backward compatibility
                   h = Relaton::Bib::HashParserV1.hash_to_bib(value)
                   Relaton::Bib::ItemData.new(**h)
                 else
                   # 2.x YAML format (docidentifier:/uri:/note: keys) —
                   # parse directly with lutaml-model
                   Relaton::Bib::Item.from_yaml(value.to_yaml)
                 end
end
```

**Why `HashParserV1` for the 1.x path, not `Item.from_yaml`:**

`Relaton::Bib::Item.from_yaml` is the 2.x lutaml-model YAML parser — it only
understands 2.x field names (`docidentifier:`, `at:` for dates, etc.) and
performs no key-name translation. Passing a 1.x-format hash (with `docid:`,
integer `edition: 12`, etc.) results in:
- `TypeError: no implicit conversion of Integer into String` when lutaml-model
  encounters bare integer values in fields declared as `String`
- Silent data loss where 1.x key names are not recognised (e.g., `docid:` ignored,
  so docidentifier is nil)

`Relaton::Bib::HashParserV1` is the explicitly-provided "V1 compatibility" bridge
in relaton-bib 2.x. It accepts the full 1.x hash key vocabulary and integer
values, translating them to the 2.x `ItemData` constructor arguments.

**Strategy note:** `HashParserV1` is only on the **read path** — a migration shim
at the input boundary. The **write path** (`bibdata_to_yaml`) already uses
`ItemData#to_yaml` which emits the 2.x format. So collections that are
round-tripped (read and written back) will have their `bibdata:` block upgraded
to 2.x format going forward. This is the intended long-term migration path.

> **Note:** `force_primary_docidentifier_yaml` uses the 1.x key `"docid"` and
> is a no-op for 2.x-format hashes (where `value["docid"]` is nil). For 2.x
> format, the `primary:` flag should already be set correctly in the input.

---

### 30. `metanorma` gem — `renderer/utils.rb` `isodoc_populate` YAML round-trip and accessor changes ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch.

**Location:** `lib/metanorma/collection/renderer/utils.rb`

`isodoc_populate` populates the isodoc `@meta` object for Liquid template
rendering. It had three 1.x dependencies that break in 2.x:

1. **`@bibdata.to_hash`** — `to_hash` is gone in 2.x (see YAML round-trip
   pattern above). Replace with `YAML.safe_load(@bibdata.to_yaml, ...)`.

2. **`@bibdata.title.first.title.content`** — In 2.x the nested `.title`
   sub-object is gone (§11); `Title` directly carries `.content`. Also,
   `@bibdata.title` may be `nil` (§9). Use safe navigation.

3. **`@bibdata.docidentifier.first.id`** — In 2.x `Docidentifier#id` →
   `#content` (§16) and `docidentifier` may be `nil` (§9). Use safe navigation.

```ruby
# 1.x
def isodoc_populate
  @isodoc.info(@xml, nil)
  { navigation: indexfile(@manifest), nav_object: index_object(@manifest),
    bibdata: @bibdata.to_hash, docrefs: liquid_docrefs(@manifest),
    "prefatory-content": isodoc_builder(@xml.at("//prefatory-content")),
    "final-content": isodoc_builder(@xml.at("//final-content")),
    doctitle: @bibdata.title.first.title.content,
    docnumber: @bibdata.docidentifier.first.id }.each do |k, v|
    v and @isodoc.meta.set(k, v)
  end
end

# 2.x — YAML round-trip for bibdata hash; Array() coercion + .content for title/docid
def isodoc_populate
  @isodoc.info(@xml, nil)
  { navigation: indexfile(@manifest), nav_object: index_object(@manifest),
    bibdata: YAML.safe_load(@bibdata.to_yaml,
                            permitted_classes: [Date, Symbol]),
    docrefs: liquid_docrefs(@manifest),
    "prefatory-content": isodoc_builder(@xml.at("//prefatory-content")),
    "final-content": isodoc_builder(@xml.at("//final-content")),
    doctitle: Array(@bibdata.title).first&.content,
    docnumber: Array(@bibdata.docidentifier).first&.content }.each do |k, v|
    v and @isodoc.meta.set(k, v)
  end
end
```

**Summary of changes:**
- `@bibdata.to_hash` → `YAML.safe_load(@bibdata.to_yaml, permitted_classes: [Date, Symbol])`
- `@bibdata.title.first.title.content` → `Array(@bibdata.title).first&.content`
  (`.title` sub-object removed in 2.x §11; `Array()` handles nil/scalar/array from §9 scalar warning)
- `@bibdata.docidentifier.first.id` → `Array(@bibdata.docidentifier).first&.content`
  (`.id` → `.content` per §16; `Array()` handles nil/scalar/array per §9)

**`navigation.rb` `indexfile_title` — same pattern ✅ Fixed:**

`indexfile_title` in `renderer/navigation.rb` has the identical nested `.title`
sub-object pattern, applied to `entry.bibdata.title`:

```ruby
# 1.x
def indexfile_title(entry)
  if entry.bibdata &&
      x = entry.bibdata.title.detect { |t| t.type == "main" } ||
          entry.bibdata.title.first
    x.title.content   # nested .title sub-object — gone in 2.x
  else
    entry.title
  end
end

# 2.x — Array() coercion (§9 scalar warning); .content directly on Title (§11)
def indexfile_title(entry)
  titles = entry.bibdata && Array(entry.bibdata.title)
  if titles && !titles.empty? &&
      (x = titles.detect { |t| t.type == "main" } || titles.first)
    x.content
  else
    entry.title
  end
end
```

---

### 31. `metanorma` gem — `collection.rb` `fetch_flavor` nil guard and `.id` → `.content` ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch.

**Location:** `lib/metanorma/collection/collection.rb`

Two issues in `fetch_flavor`:

1. `@bibdata.docidentifier` can return `nil` in 2.x when no `<docidentifier>`
   elements are present (§9). Calling `.first` on `nil` raises `NoMethodError`.

2. `docid.id` is the 1.x accessor for the identifier string. In 2.x it is
   `docid.content` (§16).

```ruby
# 1.x
def fetch_flavor
  docid = @bibdata.docidentifier.first or return
  f = docid.type.downcase || docid.id.sub(/\s.*$/, "").downcase or return
  # ...
end

# 2.x — safe navigation for nil collection (§9), .content for identifier (§16)
def fetch_flavor
  docid = @bibdata&.docidentifier&.first or return
  f = docid.type&.downcase || docid.content&.sub(/\s.*$/, "")&.downcase or return
  # ...
end
```

---

### 32. `edition` — plain string → structured `Edition` object

In Relaton 1.x, `BibliographicItem#edition` returned a plain Ruby String:

```yaml
# 1.x YAML (from to_hash / collection YAML)
edition: '1'
edition: 12          # integer also accepted by HashConverter
```

```ruby
# 1.x
bib.edition   # => "1" (String)
```

In Relaton 2.x, `ItemData#edition` is declared as `attribute :edition, Edition`
where `Edition` is a structured object with `content` and `number` attributes:

```yaml
# 2.x YAML (from to_yaml / collection YAML)
edition:
  content: '1'
```

```ruby
# 2.x
bib.edition         # => Relaton::Bib::Edition instance (or nil)
bib.edition.content # => "1" (String)
bib.edition.number  # => nil (or String if set)
```

**Impact on collection YAML fixtures:** Any collection YAML file that includes
inline `bibdata:` with a flat `edition: "N"` must be updated to the structured
form `edition:\n  content: "N"`.

**Impact on code:** Any code that compares `bib.edition == "1"` or uses it as a
string directly must use `bib.edition&.content` instead.

**`HashParserV1` handles the 1.x integer form:** The `HashParserV1.hash_to_bib`
bridge correctly translates `edition: 12` (Integer from 1.x YAML) into an
`Edition` object. So existing 1.x collection YAML files with integer `edition:`
values will still parse correctly through the 1.x path. The integer-to-string
conversion is handled inside `HashParserV1`.

---

### 33. `fetch_flavor` + flavor gem circular dependency — `metanorma-iho` / `metanorma-standoc` ⚠️ TODO

> **Status:** **Blocked** — circular dependency between `metanorma`, `metanorma-standoc`,
> and `metanorma-iho`. Cannot be resolved until `metanorma-standoc` migration is
> complete.

**The problem:**

When `fetch_flavor` runs for a collection with IHO bibdata, it calls:
```ruby
require ::Metanorma::Compile.new.stdtype2flavor_gem("iho")
# => require "metanorma-iho"
```

Loading `metanorma-iho` triggers `NameError: uninitialized constant RelatonBib`
because `metanorma-iho` depends on `metanorma-standoc`, which has not yet been
fully migrated to Relaton 2.x and still references `RelatonBib` at load time.

The circular dependency chain:
```
metanorma (this gem, migrating)
  → fetch_flavor → require "metanorma-iho"
    → metanorma-iho depends on metanorma-standoc (not yet migrated)
      → metanorma-standoc references RelatonBib → NameError
        → but metanorma-standoc depends on metanorma... (circular)
```

**Current workaround (in `collection.rb`):**
```ruby
rescue LoadError, NameError
  nil
end
```
`fetch_flavor` now catches `NameError` and returns `nil`, falling back to
`"standoc"` flavor. This prevents a hard crash but means:
- IHO-specific processor (`metanorma-iho`) is not used
- `Metanorma::Standoc::Processor` is used instead (no `fonts_manifest` method)
- The "extract custom fonts from collection XML for PDF" test **fails** with
  `NoMethodError: undefined method 'fonts_manifest'` from `location_manifest`

**Also fixed:** `FontistHelper.location_manifest` now guards against processors
that don't implement `fonts_manifest` (defensive fix independent of the
circular dependency):

```ruby
def self.location_manifest(processor, source_attributes)
  return nil unless processor.respond_to?(:fonts_manifest) &&
                    !processor.fonts_manifest.nil?
  # ...
end
```

**Resolution plan:**
1. Migrate `metanorma-standoc` to Relaton 2.x (in progress on its `fix/relaton-2.0` branch)
2. Once `metanorma-standoc` is migrated, re-run `metanorma-iho` tests
3. Migrate `metanorma-iho` to Relaton 2.x
4. The "extract custom fonts" test should then pass with `metanorma-iho` loading correctly

**Affected test:**
`spec/collection/collection_spec.rb` — "extract custom fonts from collection XML for PDF"
(test uses `collection-iho.yml` fixture; expects IHO fonts Mitimasu/Monoisome).

---

### 34. `metanorma` gem — `document.rb` `from_xml`: `<bibitem>` always uses `Relaton::Bib::Bibitem` ✅ Fixed

> **Status:** **Resolved** on `fix/relaton-2.0` branch. Refinement of §28.

**Location:** `lib/metanorma/collection/document/document.rb`

**Design rule:**

| XML element | Parser class | Reason |
|---|---|---|
| `<bibitem>` | Always `Relaton::Bib::Bibitem` | `<bibitem>` is flavor-independent by design — it appears as a cross-reference target and in `<relation>` blocks, and the `BibitemShared` module explicitly removes the `<ext>` mapping |
| `<bibdata>` | Flavor-specific `Bibdata` (e.g. `Relaton::Iso::Bibdata` for an ISO collection) | `<bibdata>` carries flavor-specific metadata in `<ext>` — the flavor must be respected |

An ISO collection contains ISO `<bibdata>` elements (with ISO-specific `<ext>` content).
It also contains `<bibitem>` elements (in `<relation>` blocks etc.) that should be
parsed as plain relaton items regardless of the surrounding collection's flavor.

**Before (§28 first implementation):**

```ruby
def from_xml(xml)
  b = xml.at("//xmlns:bibitem|//xmlns:bibdata")
  # Passed bibdata: b.name == "bibdata" to mn2relaton_parser
  # → for a <bibitem> in an ISO collection this returned Relaton::Iso::Bibitem
  r = mn2relaton_parser(xml.root["flavor"],
                        bibdata: b.name == "bibdata")
  b.xpath("//xmlns:fmt-identifier").each(&:remove)
  r.from_xml(b.to_xml)
end
```

**After:**

```ruby
def from_xml(xml)
  b = xml.at("//xmlns:bibitem|//xmlns:bibdata")
  # <bibitem> elements are always flavor-independent: use the base
  # Relaton::Bib::Bibitem regardless of collection flavor.
  # <bibdata> elements carry flavor-specific metadata (<ext> etc.) and
  # must be parsed with the appropriate flavor Bibdata class.
  r = if b.name == "bibitem"
        ::Relaton::Bib::Bibitem
      else
        mn2relaton_parser(xml.root["flavor"], bibdata: true)
      end
  b.xpath("//xmlns:fmt-identifier").each(&:remove)
  r.from_xml(b.to_xml)
end
```

The `mn2relaton_parser` method is unchanged — the `bibdata:` keyword parameter is
retained for future use. The `bibdata: false` / Bibitem-returning branches in
`mn2relaton_parser` are now unreachable from `from_xml` but remain in place.

**Impact on round-trip fidelity:**

`Relaton::Iso::Bibitem` (and `Relaton::Iso::Bibdata`) currently strip the language
suffix from `iso-with-lang` and `iso-reference` docidentifiers (e.g., `(E)`) and
auto-populate the ICS `<text>` element from the `isoics` gem lookup. See §35 and
§36 for the upstream bug reports filed against `relaton-iso`.

By using `Relaton::Bib::Bibitem` for all `<bibitem>` elements, these round-trip
fidelity bugs are avoided for the `<bibitem>` path. They remain present (and are
tracked upstream) for the `<bibdata>` path.

---

### 35. ⚠️ Known upstream bug — `relaton-iso`: `(E)` suffix stripped from `iso-with-lang`/`iso-reference` docidentifiers

> **Status:** Bug filed upstream against `relaton-iso` / `pubid-iso`. Not yet fixed.
> Do **not** remove `(E)` from test fixtures as a workaround.

**Gem:** `relaton-iso` (affects `Relaton::Iso::Bibdata` and `Relaton::Iso::Bibitem`)

**Observed behaviour:**

When an ISO bibdata element is round-tripped through `Relaton::Iso::Bibdata.from_xml`
→ `to_xml`, the language suffix `(E)` is stripped from `iso-with-lang` and
`iso-reference` type docidentifiers:

```xml
<!-- Input -->
<docidentifier type="iso-with-lang">ISO 17301-1:2016(E)</docidentifier>
<docidentifier type="iso-reference">ISO 17301-1:2016(E)</docidentifier>

<!-- Output after Relaton::Iso::Bibdata.from_xml → .to_xml -->
<docidentifier type="iso-with-lang">ISO 17301-1:2016</docidentifier>
<docidentifier type="iso-reference">ISO 17301-1:2016</docidentifier>
```

**Not affected:** `Relaton::Bib::Bibdata.from_xml` correctly preserves `(E)`.

**Root cause (suspected):** `Relaton::Iso::Docidentifier` parses the identifier
content via the `pubid-iso` gem, which normalizes the identifier string and
discards the language qualifier.

**Impact:** Any test fixture with `iso-with-lang` or `iso-reference` docidentifiers
that include `(E)` will fail round-trip equality checks when the round-trip path
goes through `Relaton::Iso::Bibdata`.

**Workaround in `metanorma` gem:** Since `<bibitem>` elements now always use
`Relaton::Bib::Bibitem` (§34), the `(E)` bug is avoided on the `<bibitem>` path.
The `<bibdata>` path is still affected when flavor is ISO.

---

### 36. ICS `<text>` auto-populated from `isoics` lookup — accepted behaviour, update fixtures

> **Status:** Accepted behaviour. No bug report. Update XML test fixtures to include
> the `isoics`-resolved `<text>` element.

**Gem:** `relaton-iso`

**Observed behaviour:**

When an ISO bibdata element containing `<ics><code>N</code></ics>` is round-tripped
through `Relaton::Iso::Bibdata.from_xml` → `to_xml`, the optional `<text>` child
element is **auto-populated** from an `isoics` gem lookup:

```xml
<!-- Input -->
<ics><code>67.060</code></ics>

<!-- Output after Relaton::Iso::Bibdata.from_xml → .to_xml -->
<ics>
  <code>67.060</code>
  <text>Cereals, pulses and derived products</text>
</ics>
```

**The grammar** (from the ICS RelaxNG schema and the `isoics` gem) defines
`<text>` as optional:

```rnc
ics = element ics {
  element code { text },
  element text { text }?
}
```

**Rationale for acceptance:** Enriching ICS entries with human-readable description
text via `isoics` is a deliberate feature of `relaton-iso`. The `<text>` element
is valid per the grammar, and the auto-population provides useful data. There are
no code implications in the `metanorma` gem.

**Required action:** Any XML test fixture that contains bare `<ics><code>N</code></ics>`
elements (without `<text>`) must be updated to include the `<text>` description
string that `isoics` will inject. This is a fixture-only update — no code changes
are required.

**Note:** This only affects the `<bibdata>` parse path (§34). `<bibitem>` elements
always use `Relaton::Bib::Bibitem` which does not perform the `isoics` enrichment.

---

### 37. Date granularity preserved in XML bibdata round-trip ✅ Correct behaviour

> **Status:** Confirmed correct behaviour in 2.x. No code changes required.

**Context:** When an XML document (e.g. an ISO standard XML file) is included in
an XML collection and the collection is round-tripped — parsed and re-serialized —
the `<date>` elements in the included document's `<bibdata>` are processed through
the Relaton 2.x `StringDate` type.

**What changed from 1.x:**

In Relaton 1.x, date values were parsed as Ruby `Date` objects. A year-month date
such as `2017-02` would be interpreted as `Date.parse("2017-02")` → `2017-02-01`
(defaulting the day to 01). The round-tripped XML would therefore contain
`2017-02-01` instead of the original `2017-02`, silently losing the input
granularity.

In Relaton 2.x, `StringDate::Value` preserves the original ISO 8601 granularity:

```xml
<!-- Input (in the XML document's <bibdata>) -->
<date type="published"><on>2017-02</on></date>

<!-- Output after round-trip through Relaton::Iso::Bibdata (or Relaton::Bib::Bibdata) -->
<date type="published"><on>2017-02</on></date>
```

`Core::DateParser#parse_date(str: true)` normalizes the date string to one of
`"YYYY"`, `"YYYY-MM"`, or `"YYYY-MM-DD"` depending on the precision of the input —
it does **not** default missing components. The value `2017-02` stays `2017-02`.

**Implication for test fixtures:** XML fixtures that previously had year-month
dates expanded to `YYYY-MM-DD` (due to the 1.x Ruby `Date` parsing) should be
updated to the more precise `YYYY-MM` form. Conversely, fixtures that rely on the
old day-defaulting behaviour must be reviewed.

See also §18 (`Date#on` → `#at`) and §21 (`Series#from`/`Series#to`) for the full
`StringDate` API reference.

---

### 38. Ruby `Date` objects in YAML must be stringified before passing to Relaton 2.x

In Relaton 1.x, the hash-based API (`HashConverter.hash_to_bib`,
`BibliographicItem.from_hash`) accepted Ruby `Date` objects as date field values.
The date was converted to a string internally.

In Relaton 2.x, lutaml-model's YAML parser (`Item.from_yaml`) expects date values
to be **plain strings** (ISO 8601 format). Passing a native Ruby `Date` object —
e.g. one produced by `YAML.safe_load(..., permitted_classes: [Date])` — causes a
type error or silent data loss because lutaml-model cannot coerce a `Date` object
into its `StringDate` type.

#### Affected pattern

Any code that:
1. Parses a YAML document with `YAML.safe_load(..., permitted_classes: [Date])`, and
2. Passes the resulting hash (which may contain Ruby `Date` values) to any Relaton
   2.x YAML constructor (`Item.from_yaml`, `HashParserV1.hash_to_bib`, etc.)

must first recursively stringify all `Date` values in the parsed hash.

#### Example — `ext_dochistory_cleanup` in `metanorma-standoc`

Document history YAML embedded in AsciiDoc sourcecode blocks contains bare date
scalars (e.g. `date: 2024-01-15`). Psych converts these to `Date` objects when
`permitted_classes: [Date]` is specified.

```ruby
# 1.x — safe_load output went to HashConverter which handled Date objects
yaml = YAML.safe_load(a.text, permitted_classes: [Date])

# 2.x — must stringify Date objects before passing hash to Relaton
yaml = yaml_deep_stringify_dates(
         YAML.safe_load(a.text, permitted_classes: [Date]))
```

```ruby
# Helper — recursively convert Ruby Date objects to ISO 8601 strings
def yaml_deep_stringify_dates(obj)
  case obj
  when Hash  then obj.transform_values { |v| yaml_deep_stringify_dates(v) }
  when Array then obj.map { |v| yaml_deep_stringify_dates(v) }
  when Date  then obj.to_s   # => "2024-01-15"
  else            obj
  end
end
```

> **Note:** `YAML.safe_load` must still include `permitted_classes: [Date]` to avoid
> `Psych::DisallowedClass` errors when the YAML contains bare date scalars. The
> `yaml_deep_stringify_dates` helper is applied **after** parsing to convert all
> `Date` values to strings before the hash is handed to Relaton.

---

### 39. `HashParserV1` — no default `role` for contributors; must be supplied explicitly

In Relaton 1.x, `HashConverter.hash_to_bib` applied a default `role` value of
`"author"` to any contributor hash that did not explicitly specify a role.

In Relaton 2.x, `Relaton::Bib::HashParserV1.hash_to_bib` does **not** inject a
default role. A contributor hash without an explicit `role` key produces a
`Relaton::Bib::Contributor` with no `<role>` child element — so `<role type="author"/>`
(or any other role element) is silently absent from the serialized XML.

#### Symptom

Test or production code that passes contributor hashes without a `"role"` key
and then compares the resulting XML will find `<role type="author"/>` missing:

```xml
<!-- 1.x output (default role injected by HashConverter) -->
<contributor>
  <role type="author"/>
  <person>...</person>
</contributor>

<!-- 2.x output (no default role — <role> element absent) -->
<contributor>
  <person>...</person>
</contributor>
```

#### Fix

Wherever contributor hashes are assembled before being passed to
`HashParserV1.hash_to_bib` (or `Item.from_yaml`), ensure every contributor
entry carries an explicit `role` key. In `metanorma-standoc`, the fix was applied
in `ext_contributors_process(yaml, ins)` in `dochistory.rb`:

```ruby
# Before — role was omitted, relying on 1.x HashConverter default
y["contributor"].each do |c|
  ins.next = contributor_hash2xml(c)
end

# After — inject "author" as the default role when none is present
y["contributor"].each do |c|
  c["role"] ||= "author"
  ins.next = contributor_hash2xml(c)
end
```

The general principle: **do not rely on Relaton to supply a default contributor
role.** If your business logic implies a default (e.g., `"author"` for document
history entries), set it explicitly in the hash before passing to Relaton 2.x.

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
