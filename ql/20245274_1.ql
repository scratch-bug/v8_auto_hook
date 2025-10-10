import cpp

/* is_stable 호출 탐지: 타깃 심볼 매칭 + 해석 실패 시 텍스트 폴백 */
cached predicate isStableCall(FunctionCall c) {
  exists(Function callee |
    c.getTarget() = callee and
    (callee.getName() = "is_stable" or callee.getQualifiedName().regexpMatch("\\bis_stable\\b"))
  )
  or
  (
    not exists(Function callee | c.getTarget() = callee) and
    c.toString().regexpMatch("\\bis_stable\\s*\\(")
  )
}

/* f 안에서 is_stable()이 최소 한 번이라도 호출되는지 판단 */
predicate functionHasIsStable(Function f) {
  exists(FunctionCall c |
    c.getEnclosingFunction() = f and
    isStableCall(c)
  )
}

from Function f
where functionHasIsStable(f)
select f, "is_stable() call in this function", f.getLocation()
