/**
 * Detect uses of ValueType ref-paths (20-bit HeapType encoding) where the
 * argument appears to come from canonical-like containers (heuristic)
 * and the enclosing function does NOT contain a CheckMaxCanonicalIndex/
 * kV8MaxWasmTypes-style guard.
 */

import cpp

predicate hasCanonicalGuard(Function f) {
  exists(Call guard |
    guard.getEnclosingFunction() = f and
    guard.toString().regexpMatch(
      "(?i)(CheckMaxCanonicalIndex\\s*\\(|\\bkV8MaxWasmTypes\\b|\\bCheckMaxCanonicalIndex\\b|DCHECK_LE\\s*\\([^)]*kMaxCanonicalTypes|<=\\s*kV8MaxWasmTypes|<\\s*kV8MaxWasmTypes)"
    )
  )
}

from Call sinkCall, Function callee, Function encl
where
  sinkCall.getTarget() = callee and
  encl = sinkCall.getEnclosingFunction() and
  (
    callee.getQualifiedName().regexpMatch("(^|::)ValueType::RefMaybeNull($|::)")
    or callee.getQualifiedName().regexpMatch("(^|::)ValueType::Ref($|::)")
    or callee.getQualifiedName().regexpMatch("(^|::)ValueType::RefNull($|::)")
    or callee.getQualifiedName().regexpMatch("(^|::)HeapTypeField::encode($|::)")
  ) and
  sinkCall.toString().regexpMatch("(?i)(isorecursive_canonical_type_ids|canonical_supertypes_|\\bcanonical\\b)") and
  not hasCanonicalGuard(encl)
select
  sinkCall, sinkCall.getLocation(),
  "Suspicious: canonical-like value flows into a ValueType/HeapType 20-bit encoding sink in this function, and no CheckMaxCanonicalIndex/kV8MaxWasmTypes-style guard was found. Manually inspect for missing range checks or use of full canonical ids."
