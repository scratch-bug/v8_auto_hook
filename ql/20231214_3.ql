import cpp

from Function f, FunctionCall u, FunctionCall c
where
  f.getQualifiedName().regexpMatch(".*ValueDeserializer::ReadJSObjectProperties$") and
  f.getFile().getRelativePath().regexpMatch(".*/(deserial|value).*\\.(cc|cpp)$") and

  u.getEnclosingFunction() = f and
  c.getEnclosingFunction() = f and

  exists(Function tu |
    tu = u.getTarget() and tu.getQualifiedName().regexpMatch(".*::Map::Update$")
  ) and
  c.getTarget().getName() = "CommitProperties" and
  c.getLocation().getStartLine() > u.getLocation().getStartLine() and

  not exists(FunctionCall g |
    g.getEnclosingFunction() = f and
    g.getLocation().getStartLine() > u.getLocation().getStartLine() and
    g.getLocation().getStartLine() < c.getLocation().getStartLine() and
    exists(Function tg |
      tg = g.getTarget() and
      (
        tg.getName() = "Normalize" or
        tg.getName() = "IsDictionaryMap" or
        tg.getName() = "is_dictionary_map" or
        tg.getName() = "CanHaveMoreTransitions"
      )
    )
  )
select c, c.getLocation(), u, "Map::Update 이후 가드 없이 CommitProperties 호출 — fast/dictionary 불일치 위험."
