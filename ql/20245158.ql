import cpp

// -----------------------------
// Guard-text heuristic (tweak regex to your repo's guard names if needed)
// -----------------------------
private predicate hasGuardText(Stmt s) {
  s.toString().regexpMatch(
    "(IsJSObject\\s*\\(|IsJSProxy\\s*\\(|IsWasmObject\\s*\\(|IsJSReceiver\\s*\\(|CheckJSObject\\s*\\(|CheckPrototypeIsJSObject\\s*\\(|CheckMaps\\s*\\(|TryBuildMapGuard\\s*\\()"
  )
}

// -----------------------------
// isGetCurrentLikeCall: 넓은 후보군
// - GetCurrent<T>(), iter.GetCurrent<T>(), Current<T>(), GetPrototype<T>(), GetPrototypeObject<T>()
// - 템플릿 표기뿐 아니라 멤버 호출 형태도 포괄
// -----------------------------
predicate isGetCurrentLikeCall(Call c) {
  c.getTarget().getName().regexpMatch("(GetCurrent|Current|GetPrototype|GetPrototypeObject)")
  and
  c.toString().regexpMatch(
    "(GetCurrent\\s*<)|(Current\\s*<)|(GetPrototype\\s*<)|(GetPrototypeObject\\s*<)|(\\.\\s*(GetCurrent|Current|GetPrototype|GetPrototypeObject)\\s*<)"
  )
}

// -----------------------------
// Direct cast detection (calls that perform casts to JSObject)
// - JSObject::cast(...)
// - Handle<JSObject>::cast(...)
// - static_cast<JSObject>(...)
// -----------------------------
predicate isDirectJSObjectCast(Call c) {
  c.toString().regexpMatch(
    "(JSObject::cast\\s*\\()|((Handle\\s*<\\s*JSObject\\s*>)\\s*::\\s*cast\\s*\\()|(static_cast\\s*<\\s*JSObject\\s*>\\s*\\()"
  )
}

// -----------------------------
// Inline-cast-of-GetCurrent: JSObject::cast(iter.GetCurrent<JSObject>()) 등
// -----------------------------
predicate isInlineCastOfGetCurrent(Call c) {
  c.toString().regexpMatch(
    "JSObject::cast\\s*\\(.*GetCurrent\\s*<\\s*JSObject\\s*>\\s*\\)|Handle\\s*<\\s*JSObject\\s*>\\s*::\\s*cast\\s*\\(.*GetCurrent\\s*<\\s*JSObject\\s*>\\s*\\)|static_cast\\s*<\\s*JSObject\\s*>\\s*\\(.*GetCurrent\\s*<\\s*JSObject\\s*>\\s*\\)"
  )
}

// -----------------------------
// Broad inline pattern: JSObject::cast(...) whose argument text contains GetCurrent<JSObject>
// -----------------------------
predicate isCastCallWithGetCurrentArg(Call c) {
  c.toString().regexpMatch("JSObject::cast\\s*\\(.*GetCurrent\\s*<\\s*JSObject\\s*>.*\\)")
}

// -----------------------------
// Single unified query
// -----------------------------
from Call c, Function f, string kind
where
  (
    isGetCurrentLikeCall(c) and f = c.getEnclosingFunction()
    and not exists(Stmt g | g.getEnclosingFunction() = f and hasGuardText(g))
    and kind = "GetCurrent-like call WITHOUT obvious IsJSObject/IsWasmObject/IsJSProxy guard (heuristic)"
  )
  or
  (
    isGetCurrentLikeCall(c)
    and kind = "GetCurrent-like call (candidate)"
  )
  or
  (
    isDirectJSObjectCast(c)
    and kind = "Direct cast to JSObject (JSObject::cast / Handle<JSObject>::cast / static_cast<JSObject>)"
  )
  or
  (
    isInlineCastOfGetCurrent(c)
    and kind = "Inline cast of GetCurrent<JSObject>() result"
  )
  or
  (
    isCastCallWithGetCurrentArg(c)
    and kind = "Cast call whose arg contains GetCurrent<JSObject> (text match)"
  )
select c, c.getLocation(), kind
