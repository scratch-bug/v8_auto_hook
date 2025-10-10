import cpp

predicate usesMapReliance(Function f) {
  exists(Stmt s |
    s.getEnclosingFunction() = f and
    s.toString().regexpMatch("\\bRelyOnMaps(PreferStability|ViaStability)\\b|\\bInferMapsUnsafe\\b|\\bkReliableMaps\\b")
  )
}

predicate mentionsArrayPushSpecialization(Function f) {
  exists(Stmt s |
    s.getEnclosingFunction() = f and
    s.toString().regexpMatch("Array(\\.prototype)?\\.push|ReduceArray.*Push|TryReduceArray.*Push")
  )
}

predicate lacksExplicitMapGuards(Function f) {
  not exists(Stmt s |
    s.getEnclosingFunction() = f and
    s.toString().regexpMatch("\\b(CheckMaps|CheckStableMap|BuildCheckMaps|TryBuildMapGuard|MapGuard)\\b")
  )
}

from Function f
where usesMapReliance(f) and mentionsArrayPushSpecialization(f) and lacksExplicitMapGuards(f)
select
  f,
  f.getLocation(),
  "Map-reliance for Array.push specialization without explicit CheckMaps/MapGuard in the same body"
