import cpp

predicate inEAContext(Function f) {
  f.getQualifiedName().regexpMatch("(?i)(EscapeAnalysis|Escape|EA|Reducer|Reduce|Visit|Build|Analyze|ReduceNode)")
  or exists (File fi | fi = f.getFile() and fi.getRelativePath().regexpMatch("escape"))
}

predicate hasEscapeOrDeoptGuard(Stmt s) {
  exists(Call c, Function cal |
    c.getEnclosingStmt*() = s and c.getTarget() = cal and
    (
      cal.getQualifiedName().regexpMatch("(?i)(SetEscaped|MarkEscaped|SetVirtualObjectEscaped)")
      or cal.getName().regexpMatch("(?i)(SetEscaped|MarkEscaped)")
      or cal.getQualifiedName().regexpMatch("(?i)(Deoptimize|DeoptimizeIf|BailoutIf|AbortIf)")
      or cal.getName().regexpMatch("(?i)(Deoptimize|Bailout|Abort)")
    )
  )
}

predicate hasEAStateTransitionCall(Stmt s) {
  exists(Call c1, Function cal1 |
    c1.getEnclosingStmt*() = s and c1.getTarget() = cal1 and
    (
      cal1.getName().regexpMatch("^Set$|^SetReplacement$|^SetVirtualObject$|^MarkForDeletion$|^SetValueChanged$")
      or cal1.getQualifiedName().regexpMatch("(Set|SetReplacement|SetVirtualObject|MarkForDeletion|SetValueChanged)$")
    )
  )
  or exists(Expr e |
    e.getEnclosingStmt*() = s and
    e.toString().regexpMatch("\\b(SetReplacement|SetVirtualObject|MarkForDeletion|SetValueChanged|Set\\s*\\()")
  )
}

predicate isIfBranchArm(Stmt s) {
  exists(IfStmt i | s = i.getThen() or s = i.getElse())
}

predicate isInsideSwitch(Stmt s) {
  exists(SwitchStmt sw | s.getParent*() = sw)
}

from Stmt s, Function fn, File f
where
  (isIfBranchArm(s) or isInsideSwitch(s)) and
  f = s.getFile() and
  fn = s.getEnclosingFunction()  and
  hasEAStateTransitionCall(s) and
  not hasEscapeOrDeoptGuard(s)
select
  s,
  "EA-state transition in branch without SetEscaped/Deopt",
  s.getLocation()
// and inEAContext(fn)