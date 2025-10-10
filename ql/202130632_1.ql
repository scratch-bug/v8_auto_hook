import cpp

/**
 * is_stable 호출 탐지: 타깃 심볼 매칭 + 해석 실패 시 텍스트 폴백
 * 결과는 함수(Function) 당 한 행만 나오며, 호출 위치(Location)를 함께 출력합니다.
 */

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

/*
 Strategy:
  - Function f 단위로 묶음
  - f 내부에 isStableCall을 만족하는 FunctionCall c가 존재하는지 검사
  - 존재하면 그 함수와 (그 함수 안에서 발견된) 첫 번째 호출의 위치(loc)를 결과로 출력
*/
from Function f, Location loc
where
  /* (선택) 컴파일러 디렉터리로 한정하려면 아래 and 절의 주석 제거 */
  /* and inCompilerFile(f) */
  exists(FunctionCall c |
    c.getEnclosingFunction() = f and
    isStableCall(c) and
    c.getLocation() = loc
  )
select f, loc, "contains is_stable() call", f.getFile()
