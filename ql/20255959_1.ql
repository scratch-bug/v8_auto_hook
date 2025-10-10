import cpp

from IfStmt ifs, ReturnStmt ret
where
  exists(Call c |
    c = ret.getExpr() and
    exists(Function f | f = c.getTarget() and f.getName() = "EqualTypeIndex")
  ) and
  ifs.getCondition().toString().regexpMatch("(?i)\\bhas_index\\b|\\bindexed\\b") and
  ret.getEnclosingStmt*() = ifs.getThen() and
  not ret.getExpr().toString().regexpMatch("(?i)is_equal_except_index|\\&\\&|&&")
select ret, ret.getLocation(), "Return inside an 'indexed/has_index' branch returns only EqualTypeIndex(...); considers index-only equality without extra bit checks."
