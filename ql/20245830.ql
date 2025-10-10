import cpp

predicate isDcheck(Stmt s) {
  s.toString().regexpMatch("\\bDCHECK(_[A-Z]+)?\\s*\\(")
  or s.toString().regexpMatch("\\bCHECK\\s*\\(")
}

predicate isUpdateAssignToMap(Stmt s) {
  s.toString().regexpMatch("(?s)\\bmap\\s*=\\s*Update\\s*\\(")
}

predicate isCallWithMapArg(Stmt s) {
  s.toString().regexpMatch("(?s)\\b[A-Za-z_][A-Za-z_0-9]*\\s*\\([^;]*\\bmap\\b[^;]*\\)")
}

predicate strictlyPrecedes(Stmt a, Stmt b) {
  a.getFile() = b.getFile() and
  a.getLocation().getStartLine() < b.getLocation().getStartLine()
}

from Function f, Stmt sUpdate, Stmt sCall
where
  sUpdate.getEnclosingFunction() = f and
  sCall.getEnclosingFunction() = f and
  isUpdateAssignToMap(sUpdate) and
  strictlyPrecedes(sUpdate, sCall) and
  isCallWithMapArg(sCall) and
  not exists(Stmt mid |
    mid.getEnclosingFunction() = f and
    strictlyPrecedes(sUpdate, mid) and strictlyPrecedes(mid, sCall) and
    not isDcheck(mid)
  )
select
  sCall,
  sUpdate,
  sCall.getLocation(),
  "Calls a function with 'map' immediately after 'map = Update(isolate, map)', ignoring intervening DCHECKs."
