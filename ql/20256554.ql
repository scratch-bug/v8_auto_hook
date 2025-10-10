import cpp

/**
 * Heuristic: find functions that call a "variable-load helper" (i.e., emit/load a JS-variable
 * from frame/context), but that do NOT contain the usual hole-check / remember-hole-check calls.
 *
 * Restrict the search to likely generator code (e.g., bytecode-generator.cc) to reduce noise.
 */

predicate isVarLoadHelper(Call c) {
  exists(Function callee |
    callee = c.getTarget() and
    callee.getName().regexpMatch("(?i)^(LoadVariable|LoadFromFrame|LoadContextSlot|BuildVariableLoad|VisitVariable|EmitLoadSlot|LoadSlot|GetContextSlot|GetLocal|GetFrameSlot)$")
  )
}

predicate isHoleCheckCall(Call c) {
  exists(Function callee |
    callee = c.getTarget() and
    callee.getName().regexpMatch("(?i)(BuildThrowIfHole|ThrowReferenceErrorIfHole|ThrowIfHole|CheckIfHole|ThrowIfHoleForVariable)")
  )
}

predicate isRememberHoleCheckCall(Call c) {
  exists(Function callee |
    callee = c.getTarget() and
    callee.getName().regexpMatch("(?i)(RememberHoleCheckInCurrentBlock|RememberHoleCheckInBitmap|RememberHoleCheck|MarkHoleChecked)")
  )
}

from Function f, Call loadCall
where
  f.getFile() = loadCall.getFile() and
  loadCall.getEnclosingFunction() = f and
  isVarLoadHelper(loadCall) and
  not exists(Call c | c.getEnclosingFunction() = f and isHoleCheckCall(c)) and
  not exists(Call d | d.getEnclosingFunction() = f and isRememberHoleCheckCall(d))
select
  f,
  loadCall,
  "This function calls a variable-load helper but contains no hole-check or remember-hole-check calls; review whether TDZ checks are missing.",
  loadCall.getLocation()
