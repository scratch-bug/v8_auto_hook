import cpp

/** ForceContextAllocation 호출 */
class ForceCtxCall extends FunctionCall {
  ForceCtxCall() {
    exists(Function t |
      t = this.getTarget() and t.getName() = "ForceContextAllocation"
    )
  }
}

/** set_is_used 호출 */
class SetIsUsedCall extends FunctionCall {
  SetIsUsedCall() {
    exists(Function t |
      t = this.getTarget() and t.getName() = "set_is_used"
    )
  }
}

/** CFG 없이 소스 라인 비교로 선후관계 근사 */
predicate strictlyPrecedes(Stmt a, Stmt b) {
  a.getFile() = b.getFile() and
  a.getLocation().getStartLine() < b.getLocation().getStartLine()
}

from Function f, ForceCtxCall fc, Stmt sFC
where
  fc.getEnclosingFunction() = f and
  sFC = fc.getEnclosingStmt() and
  not exists(SetIsUsedCall su, Stmt sSU |
    su.getEnclosingFunction() = f and
    sSU = su.getEnclosingStmt() and
    strictlyPrecedes(sSU, sFC)
  )
select fc,
  "ForceContextAllocation() without any earlier set_is_used() in this function (source-order approximation).",
  fc.getLocation()
