import cpp

predicate isWasmCandidateExpr(Expr e) {
  e.toString().regexpMatch("(?i)(shared\\(\\)->wasm_exported_function_data|wasm_exported_function_data\\b|wasm_exported_function_map\\b|WasmJSFunction\\b|WasmExportedFunction\\b|wasm_js_function\\b|wasm_exported\\b|external_function->shared\\(\\)->wasm|->wasm\\b|\\.wasm\\b)")
}

predicate isGuardConditionExpr(Expr cond) {
  cond.toString().regexpMatch("(?i)(HasWasmJSFunctionData|HasWasmJSFunction|IsWasmJSFunctionData|EnsureWasmJSFunctionData)\\s*\\(")
}

predicate containsReturn(Stmt s) { s.toString().regexpMatch("(?i)\\breturn\\b") }

predicate hasPriorEarlyReturnGuard(Function f, Expr cand) {
  (
    exists(IfStmt iff, Stmt thenS |
      iff.getEnclosingFunction() = f and
      isGuardConditionExpr(iff.getCondition()) and
      thenS = iff.getThen() and
      containsReturn(thenS) and
      iff.getLocation().getStartLine() < cand.getLocation().getStartLine()
    )
  )
  or
  (
    exists(IfStmt iff, Stmt elseS |
      iff.getEnclosingFunction() = f and
      isGuardConditionExpr(iff.getCondition()) and
      elseS = iff.getElse() and
      containsReturn(elseS) and
      iff.getLocation().getStartLine() < cand.getLocation().getStartLine()
    )
  )
}

from Function f, Expr cand
where
  cand.getEnclosingFunction() = f and
  isWasmCandidateExpr(cand) and
  not hasPriorEarlyReturnGuard(f, cand)
select
  cand,
  "Possible reach to wasm-internal access without PRIOR early-return HasWasmJSFunctionData() guard",
  f, "function",
  cand.getLocation()
