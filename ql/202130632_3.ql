import cpp

/* if 조건식 안의 is_stable() 호출 */
cached predicate isStableCallInIf(IfStmt s, FunctionCall c) {
  c.getEnclosingStmt() = s and
  exists(Function callee |
    c.getTarget() = callee and callee.getName() = "is_stable"
  )
}

/* 조건식 내 호출 총 개수가 정확히 1개인지 (= is_stable 하나만) */
cached predicate onlyOneCallInCondAndItIsStable(IfStmt s) {
  exists(FunctionCall stab | isStableCallInIf(s, stab)) and
  1 = count(FunctionCall fc | fc.getEnclosingStmt() = s)
}

/* 조건식에 논리결합/비교/삼항 토큰이 전혀 없는지 */
cached predicate condHasNoJunctionOrComparison(IfStmt s) {
  not s.getCondition().toString().regexpMatch(
    "\\|\\||\\&\\&|\\b(and|or)\\b|==|!=|<=|>=|<|>|\\?"
  )
}

/* 메인: 단독(is_stable()/!is_stable()) 조건문 + 위치 출력 */
from IfStmt s, FunctionCall stab, Function f, Location ifLoc, Location callLoc
where
  s.getEnclosingFunction() = f and
  isStableCallInIf(s, stab) and
  onlyOneCallInCondAndItIsStable(s) and
  condHasNoJunctionOrComparison(s) and
  ifLoc = s.getLocation() and
  callLoc = stab.getLocation()
select
  f, "function",
  stab, callLoc, "is_stable() here"
