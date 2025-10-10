/**
 * missing-is-uninhabited-ast-fixed.ql
 * If 조건에 kWasmBottom이 언급되는데, 같은 함수 안에 is_uninhabited류 호출이 없는 곳 찾기.
 *
 * Usage:
 *   codeql query run --database=<db> missing-is-uninhabited-ast-fixed.ql
 */
import cpp

predicate looksLikeIsUninhabited(Call c) {
  exists(Function cal |
    cal = c.getTarget() and
    (
      cal.getName().regexpMatch("(?i).*is[_]*uninhabited.*") or
      cal.getQualifiedName().regexpMatch("(?i).*is[_]*uninhabited.*")
    )
  )
}

predicate functionHasWasmBottomIf(Function f) {
  exists(IfStmt ifs |
    ifs.getEnclosingFunction() = f and
    ifs.getCondition().toString().matches("%kWasmBottom%")
  )
}

predicate functionMissesUninhabitedCall(Function f) {
  not exists(Call c |
    c.getEnclosingFunction() = f and looksLikeIsUninhabited(c)
  )
}

from Function f
where functionHasWasmBottomIf(f) and functionMissesUninhabitedCall(f)
select
  f,
  f.getLocation(),
  "kWasmBottom 비교가 있지만 is_uninhabited류 호출이 없습니다. 속성 기반 체크로 교체 필요."
