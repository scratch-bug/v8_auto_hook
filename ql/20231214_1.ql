import cpp

from Function f
where
  f.getQualifiedName().regexpMatch(".*ValueDeserializer::ReadJSObjectProperties$") and
  f.getFile().getRelativePath().regexpMatch(".*/(deserial|value).*\\.(cc|cpp)$") and

  exists(FunctionCall u |
    u.getEnclosingFunction() = f and
    exists(Function tu |
      tu = u.getTarget() and tu.getQualifiedName().regexpMatch(".*::Map::Update$")
    )
  ) and
  exists(FunctionCall c |
    c.getEnclosingFunction() = f and c.getTarget().getName() = "CommitProperties"
  )
select f, "타깃 함수에서 두 호출 모두 발견됨.", f.getLocation()
