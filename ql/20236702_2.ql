import cpp

from Function fun, Expr ctxExpr, Call callExpr
where
  ctxExpr.getEnclosingFunction() = fun and
  ctxExpr.toString().matches("%->context%") and

  callExpr.getEnclosingFunction() = fun and
  callExpr.toString().matches("%->get(%") and

  callExpr.toString().matches("%" + ctxExpr.toString() + "%") and

  not exists(Call g |
    g.getEnclosingFunction() = fun and
    g.toString().matches("%IsNativeContext%") and
    g.toString().matches("%" + ctxExpr.toString() + "%")
  )
select callExpr, callExpr.getLocation(), ctxExpr,
  "Heuristic: found context->get(...) candidate without textual IsNativeContext check in the same function. Review for CVE-2023-6702-like pattern."
