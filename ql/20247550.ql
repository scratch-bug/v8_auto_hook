/**
 * detect-prototype-unsafe-cast.ql
 *
 * Find functions that reference prototype-like operations and also perform
 * an unguarded cast / AsJSObject / JSObject::cast / Cast<JSObject> (textual heuristics).
 *
 * This is a heuristic detector: tune regexp patterns to your Chromium/V8 tree to reduce noise.
 */

import cpp

predicate mentionsPrototype(Function f) {
  exists(Expr e |
    e.getEnclosingFunction() = f and
    e.toString().regexpMatch("(?i)\\bprototype\\b|\\bGetPrototype\\b|\\bLoadPrototype\\b|\\bPrototypeSlot\\b|\\bGetPrototypeIfExists\\b")
  )
}

predicate hasUnsafeCast(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    (
      c.getTarget().getName().regexpMatch("(?i)AsJSObject|As<\\s*JSObject\\s*>|JSObject::cast|Cast<\\s*JSObject\\s*>|ToJSObject|UncheckedCastToJSObject")
      or c.toString().regexpMatch("(?i)AsJSObject|JSObject::cast|Cast<\\s*JSObject\\s*>|ToJSObject")
    )
  )
}

predicate hasGuard(Function f) {
  exists(IfStmt i |
    i.getEnclosingFunction() = f and
    i.getCondition().toString().regexpMatch("(?i)IsJSObject|IsWasmObject|IsWasmStruct|HasWasm|IsWasm|IsJSReceiver|IsHeapObject|deopt|Deoptimize|DCHECK\\(|CHECK\\(|UNLIKELY\\(|LIKELY\\(|IsJSObjectOrNull")
  )
  or
  exists(Stmt s |
    s.getEnclosingFunction() = f and
    s.toString().regexpMatch("(?i)Deoptimize|TriggerDeopt|Runtime::Deopt|RETURN_DEOPT|ThrowTypeError|if\\s*\\(.*IsJSObject")
  )
}

from Function f
where
  mentionsPrototype(f) and
  hasUnsafeCast(f) and
  not hasGuard(f)
select
  f,
  "Potential prototype→JSObject unsafe cast (prototype referenced and JSObject cast performed without an explicit IsJSObject/IsWasm guard).",
  f.getLocation()
