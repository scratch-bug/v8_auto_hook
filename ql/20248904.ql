import cpp

/**
Find functions that perform "stack/frame traversal"-like calls but do NOT
contain textual mentions or common patterns that indicate wasm continuation handling.
This avoids using Function.getBody() (which may not be available).
*/

predicate isStackTraversalCall(Call c) {
  exists(Function cal |
    cal = c.getTarget() and
    (
      cal.getName().regexpMatch("(?i)VisitThread|VisitStack|VisitFrames|IterateFrames|ForEachFrame|WalkFrames|WalkStack") or
      cal.getQualifiedName().regexpMatch("(?i)FrameIterator|StackFrameIterator|FrameWalker|StackIterator|FrameVisitor") or
      c.toString().regexpMatch("(?i)it\\.Reset\\(|it\\.reset\\(|iterator\\.Reset\\(|iterator\\.reset\\(") or
      c.toString().regexpMatch("(?i)Reset\\(\\s*top\\s*,\\s*parent\\s*\\)")
    )
  )
}

/*
Look for evidence of continuation handling inside the function by scanning
statements (and calls) inside that function. This is more robust than calling
getBody() which may not exist on this CodeQL bundle.
*/
predicate mentionsWasmContinuation(Function f) {
  exists(Stmt s |
    s.getEnclosingFunction() = f and
    (
      s.toString().regexpMatch("(?i)WasmContinuation|WasmContinuationObject|maybe_continuation|continuation_parent") or
      s.toString().regexpMatch("(?i)continuation\\s*->\\s*parent|continuation\\.parent") or
      s.toString().regexpMatch("(?i)Cast\\s*<[^>]*Continuation[^>]*>") or
      s.toString().regexpMatch("(?i)Cast\\s*<[^>]*WasmCont[^>]*>") or
      s.toString().regexpMatch("(?i)\\.parent\\s*\\(|->parent\\s*\\(")
    )
  )
  or exists(Call c |
    c.getEnclosingFunction() = f and
    c.toString().regexpMatch("(?i)maybe_continuation|continuation\\s*->\\s*parent|continuation\\.parent")
  )
}

from Function f, Call c
where
  c.getEnclosingFunction() = f and
  isStackTraversalCall(c) and
  not mentionsWasmContinuation(f)
select
  f, c,
  "Contains stack/frame-traversal-like call(s) but I cannot find textual evidence of Wasm continuation handling (e.g. WasmContinuation, Cast<...Continuation>, continuation->parent). Review whether continuations are handled.",
  c.getLocation()
