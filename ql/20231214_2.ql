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

  // 라인 번호 비교만 사용 (가벼움)
  c.getLocation().getStartLine() > u.getLocation().getStartLine()
select c, "Map::Update 이후 CommitProperties 호출.", c.getLocation()
