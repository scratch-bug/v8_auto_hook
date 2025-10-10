import cpp

// --- patterns that indicate element-size/format derived from static type tokens ---
predicate derivesElementSize(Function f) {
  exists(Expr e, string t |
    e.getEnclosingFunction() = f and
    t = e.toString() and
    (
      t.regexpMatch("\\bvalue_kind_size\\b") or
      t.regexpMatch("\\b(type\\s*->\\s*element_type\\s*\\()") or
      t.regexpMatch("\\b(Packed\\s*\\(\\s*[^)]*type\\s*->\\s*element_type)\\b") or
      t.regexpMatch("\\bElementSize\\b|\\bkElementSize\\b|\\belement_size\\b")
    )
  )
  or
  exists(Stmt s, string ts |
    s.getEnclosingFunction() = f and
    ts = s.toString() and
    (
      ts.regexpMatch("\\bvalue_kind_size\\b") or
      ts.regexpMatch("\\b(type\\s*->\\s*element_type\\s*\\()") or
      ts.regexpMatch("\\b(Packed\\s*\\(\\s*[^)]*type\\s*->\\s*element_type)\\b") or
      ts.regexpMatch("\\bElementSize\\b|\\bkElementSize\\b|\\belement_size\\b")
    )
  )
}

// --- raw memory ops / sinks that, when combined with above, increase confidence ---
predicate usesRawMemoryOps(Function f) {
  exists(Expr e, string t |
    e.getEnclosingFunction() = f and
    t = e.toString() and
    t.regexpMatch("\\b(memset|memcpy|memmove|CopyTo|CopyBytes|MemMove|VectorMemmove|ElementAddress)\\b")
  )
  or
  exists(Stmt s, string ts |
    s.getEnclosingFunction() = f and
    ts = s.toString() and
    ts.regexpMatch("\\b(memset|memcpy|memmove|CopyTo|CopyBytes|MemMove|VectorMemmove|ElementAddress)\\b")
  )
}

// --- presence of guard tokens that indicate canonical/nullability/Map checks ---
predicate hasGuard(Function f) {
  exists(Expr e, string t |
    e.getEnclosingFunction() = f and
    t = e.toString() and
    t.regexpMatch("(?i)(allow_nullable|is_nullable\\s*\\(|IsCanonical|\\bcanonical\\b|CheckMaps|CheckStableMap|TryBuildMapGuard|TypeCanonicalizer|isorecursive_canonical_type_ids|Ensure.*Map|HasSameMap)")
  )
  or
  exists(Stmt s, string ts |
    s.getEnclosingFunction() = f and
    ts = s.toString() and
    ts.regexpMatch("(?i)(allow_nullable|is_nullable\\s*\\(|IsCanonical|\\bcanonical\\b|CheckMaps|CheckStableMap|TryBuildMapGuard|TypeCanonicalizer|isorecursive_canonical_type_ids|Ensure.*Map|HasSameMap)")
  )
}

// --- final selection: high-confidence vs suspicious ---
from Function f, string severity
where
  (
    derivesElementSize(f) and usesRawMemoryOps(f) and not hasGuard(f) and
    severity = "HIGH_CONFIDENCE: derives element-size/format + raw-mem usage without guards"
  )
  or
  (
    derivesElementSize(f) and not hasGuard(f) and
    severity = "SUSPICIOUS: derives element-size/format without obvious guards"
  )
select f, severity, f.getLocation()
