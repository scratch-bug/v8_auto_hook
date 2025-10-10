/**
 * 2025-0291: find functions that trigger a loop re-visit by calling
 * AnalyzerIterator::MarkLoopForRevisitSkipHeader (or MarkLoopForRevisit).
 *
 * Usage: run this against a V8 CodeQL C/C++ database.
 */

import cpp

/** Call whose resolved target name matches MarkLoopForRevisit* */
predicate isMarkLoopRevisitCall(ExprCall c) {
  exists(Function target |
    c.getTarget() = target and
    (
      target.getName().matches("%MarkLoopForRevisitSkipHeader%") or
      target.getName().matches("%MarkLoopForRevisit%")
    )
  )
}

/** Report both the callsite and its enclosing function (with getLocation()). */
from Function f, ExprCall c
where c.getEnclosingFunction() = f and isMarkLoopRevisitCall(c)
select
  c, c.getLocation(),
  "Function " + f.getName() + " contains a call to MarkLoopForRevisit* (loop re-visit / SkipHeader)."
