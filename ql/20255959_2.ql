/**
 * @name Bit-field equality without masking index bits (optimized scope)
 * @description
 *   Detect direct equality comparisons of bit_field_-like members that do NOT mask out index bits.
 *   This version narrows the search scope to likely V8 wasm/type canonicalization files to avoid expensive full-repo scans,
 *   and uses a broader set of candidate mask/token names.
 * @kind problem
 * @id cpp/bitfield-compare-no-mask-optimized
 */

import cpp

// --- configuration: adjust these if your repo uses different paths or names ---
private predicate inLikelyWasmOrTypeFile(File f) {
  // narrow to wasm/type related files to avoid scanning entire repo
  f.getRelativePath().regexpMatch("(?i).*(/|\\\\)(src/wasm|wasm|value-type|value_type|canonical-types|canonical_type|canonical-types.h|value-type.h)($|/|\\\\).*")
}

// bit-field name tokens we care about (expand as needed)
private predicate bitFieldTokenPresent(Expr e) {
  e.toString().regexpMatch("(?i)\\b(bit_field_|bitfield_|bitField_|bit_field)\\b")
}

// broad set of possible index-mask identifiers to recognize masking usage
private predicate indexMaskTokenPresent(Expr e) {
  e.toString().regexpMatch("(?i)\\b(kIndexBits|kIndexMask|INDEX_MASK|INDEX_BITS|kTypeIndexBits|kIndex|INDEX_BITMASK|INDEX_MASK_[A-Z0-9_]+)\\b")
}

// common masking syntaxes we want to treat as "masking index bits"
// examples: (x & ~kIndexBits), ~kIndexBits, (x & kIndexMask) etc.
private predicate containsIndexMaskingSyntax(Expr e) {
  e.toString().regexpMatch("(?i)(~\\s*(kIndexBits|kIndexMask|INDEX_MASK|INDEX_BITS|kIndex)|&\\s*~\\s*(kIndexBits|kIndexMask|INDEX_MASK|INDEX_BITS|kIndex)|&\\s*(kIndexMask|INDEX_MASK|INDEX_BITS))")
  or e.toString().regexpMatch("(?i)\\bmask\\b.*\\b(index|INDEX)\\b")
}

// exclude helper function names that indicate correct handling
private predicate containsHelper(Expr e) {
  e.toString().regexpMatch("(?i)is_equal_except_index|isEqualExceptIndex|is_equal_except|equalsExceptIndex|equal_except_index")
}

// Main detection: an Expr that contains '==' and mentions bit_field on both sides (textually),
// located in likely wasm/type files, and that does NOT contain any masking or helper usage.
from Expr e, File f
where
  // only in targeted files to avoid full-repo cost
  f = e.getFile() and inLikelyWasmOrTypeFile(f) and

  // must be an equality expression (text-level)
  e.toString().regexpMatch("==") and

  // must mention bit_field-like token (on either side; broad)
  bitFieldTokenPresent(e) and

  // exclude if masking syntax or mask tokens present
  not containsIndexMaskingSyntax(e) and
  not indexMaskTokenPresent(e) and

  // exclude if helper used
  not containsHelper(e) and

  // small defensive filter: avoid extremely long expressions which can be pathological
  not e.toString().regexpMatch(".{1000,}")
select e, e.getLocation(), "Possible direct comparison of bit_field_ without masking out index bits. Consider masking the index bits (e.g. (bit_field_ & ~kIndexBits) == (other.bit_field_ & ~kIndexBits)) or using an is_equal_except_index helper."

