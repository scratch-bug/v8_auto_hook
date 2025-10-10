/**
 * @name Detect possible missing unreliable-mark logic in switch-case (safer baseline)
 * @description Detect candidate switch-case blocks where there is no marking such as `result = kUnreliableMaps` or a similar call
 * @kind problem
 */

import cpp

predicate isUnreliableMarking(Expr e) {
  exists(AssignExpr ae |
    ae = e and
    ae.getLValue().toString().matches("%result%") and
    ae.getRValue().toString().matches("%kUnreliableMaps%")
  )
  or
  exists(FunctionCall fc |
    fc = e and
    fc.getTarget().toString().matches("%Unreliable%")
  )
}

from SwitchStmt sw, SwitchCase sc, Expr child
where
  sc.getSwitchStmt() = sw and
  child = child.getAChild() and  // sc 내부 자식 표현식 탐색 (단 한 단계)
  child.getEnclosingStmt().getParentStmt*() = sc.getParentStmt*() and
  not exists(Expr f |
    f = f.getAChild() and
    f.getEnclosingStmt().getParentStmt*() = sc.getParentStmt*() and
    isUnreliableMarking(f)
  )
select sc, sc.getLocation(), "Switch-case block may lack unreliable-mark logic"
