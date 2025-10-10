import cpp

// 스택→스택 호출 휴리스틱
predicate isStackToStackCall(Call c) {
  exists(Function cal |
    cal = c.getTarget() and
    (
      cal.getName().regexpMatch("(?i).*(StackToStack|Stack.*to.*Stack|Emit.*Stack.*Stack.*Move|Spill.*Stack|Copy.*Stack.*Stack).*") or
      cal.getQualifiedName().regexpMatch("(?i).*(StackToStack|Stack.*to.*Stack|Emit.*Stack.*Stack.*Move|Spill.*Stack|Copy.*Stack.*Stack).*")
    )
  )
  or
  c.toString().regexpMatch("(?i).*(Stack[^\\n]*Stack|slot[^\\n]*slot|frame.*slot[^\\n]*slot).*")
}

// 스택→레지스터 호출 휴리스틱
predicate isStackToRegisterCall(Call c) {
  exists(Function cal |
    cal = c.getTarget() and
    (
      cal.getName().regexpMatch("(?i).*(StackToReg(ister)?|Load.*Stack.*Reg(ister)?|Emit.*Stack.*Reg(ister)?.*Move|Pop.*to.*Reg(ister)?).*") or
      cal.getQualifiedName().regexpMatch("(?i).*(StackToReg(ister)?|Load.*Stack.*Reg(ister)?|Emit.*Stack.*Reg(ister)?.*Move|Pop.*to.*Reg(ister)?).*")
    )
  )
  or
  c.toString().regexpMatch("(?i).*(Stack[^\\n]*Reg(ister)?|slot[^\\n]*Reg(ister)?|frame.*slot[^\\n]*Reg(ister)?).*")
}

// 루프 문장 식별
predicate isLoop(Stmt s) { s instanceof ForStmt or s instanceof WhileStmt or s instanceof DoStmt }

from Call s2sCall, Call s2rCall, Function f, Stmt loopStmt, Stmt a, Stmt b
where
  isStackToStackCall(s2sCall) and
  isStackToRegisterCall(s2rCall) and
  s2sCall.getEnclosingFunction() = f and
  s2rCall.getEnclosingFunction() = f and
  a = s2sCall.getEnclosingStmt() and
  b = s2rCall.getEnclosingStmt() and
  isLoop(loopStmt) and
  // 두 호출이 동일 루프 본문 텍스트 범위 안
  a.getLocation().getStartLine() >= loopStmt.getLocation().getStartLine() and
  a.getLocation().getEndLine()   <= loopStmt.getLocation().getEndLine() and
  b.getLocation().getStartLine() >= loopStmt.getLocation().getStartLine() and
  b.getLocation().getEndLine()   <= loopStmt.getLocation().getEndLine() and
  // 순서: 스택→스택이 먼저
  a.getLocation().getStartLine() < b.getLocation().getStartLine()
select
  s2rCall, s2rCall.getLocation(),
  "Stack→Stack call appears before Stack→Register call inside the same loop body (generalized heuristic)."
