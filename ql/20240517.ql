import cpp

class AllocateCall extends Call {
  AllocateCall() {
    exists(Function callee |
      callee = this.getTarget() and
      (
        callee.getName().regexpMatch("BuildAllocate.*") or
        callee.getQualifiedName().regexpMatch(".*::BuildAllocate.*")
      )
    )
  }

  predicate hasYoungAllocationTypeArg() {
    exists(int i, Expr e |
      e = this.getArgument(i) and
      e.toString().regexpMatch("(^|\\W)AllocationType\\s*::\\s*kYoung(\\W|$)")
    )
  }
}

predicate isClearRawAllocation(Call c) {
  exists(Function callee |
    callee = c.getTarget() and
    (
      callee.getName() = "ClearCurrentRawAllocation" or
      callee.getQualifiedName().regexpMatch(".*::ClearCurrentRawAllocation")
    )
  )
}

from Function f, AllocateCall alloc, ReturnStmt ret
where
  alloc.getEnclosingFunction() = f and
  ret.getEnclosingFunction() = f and
  alloc.hasYoungAllocationTypeArg() and
  ret.getLocation().getStartLine() > alloc.getLocation().getStartLine() and
  not exists(Call clr |
    isClearRawAllocation(clr) and
    clr.getEnclosingFunction() = f and
    clr.getLocation().getStartLine() > alloc.getLocation().getStartLine() and
    clr.getLocation().getStartLine() < ret.getLocation().getStartLine()
  )
select alloc, alloc.getLocation(),
  "Potential path exits function after young allocation without ClearCurrentRawAllocation()"
