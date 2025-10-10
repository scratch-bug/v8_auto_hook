import cpp

class StoreCellValue extends FunctionCall {
  StoreCellValue() {
    getTarget().getName() = "StoreField" and
    exists(int i, FunctionCall inner |
      i >= 0 and i < getNumberOfArguments() and
      inner = this.getArgument(i) and inner.getTarget().getName() = "ForPropertyCellValue"
    )
  }
}

cached predicate hasGlobalStore(Function f) {
  exists(StoreCellValue st | st.getEnclosingFunction() = f)
  or
  exists(FunctionCall c, Function g |
    c.getEnclosingFunction() = f and c.getTarget() = g and g.getName() = "ReduceJSStoreGlobal"
  )
}

cached predicate hasIsStableInIf(Function f) {
  exists(IfStmt s, FunctionCall c, Function callee |
    s.getEnclosingFunction() = f and
    c.getEnclosingFunction() = f and
    c.getEnclosingStmt() = s and
    c.getTarget() = callee and callee.getName() = "is_stable"
  )
}

predicate globalStoreLoc(Function f, Location loc) {
  exists(StoreCellValue st |
    st.getEnclosingFunction() = f and
    st.getLocation() = loc
  )
  or
  exists(FunctionCall c, Function g |
    c.getEnclosingFunction() = f and c.getTarget() = g and g.getName() = "ReduceJSStoreGlobal" and
    c.getLocation() = loc
  )
}

predicate isStableIfLoc(Function f, Location loc) {
  exists(IfStmt s, FunctionCall c, Function callee |
    s.getEnclosingFunction() = f and
    c.getEnclosingFunction() = f and
    c.getEnclosingStmt() = s and
    c.getTarget() = callee and callee.getName() = "is_stable" and
    c.getLocation() = loc
  )
}

from Function f, Location locStore, Location locIsStable
where hasGlobalStore(f) and hasIsStableInIf(f)
  and globalStoreLoc(f, locStore)
  and isStableIfLoc(f, locIsStable)
select f, locStore,
  "Function uses is_stable() in an if-condition and contains a global store."
