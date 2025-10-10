import cpp

class NewScopeCall extends Call {
  NewScopeCall() {
    this.getTarget().getName().regexpMatch("(?i)^(New|Create|Make|Allocate|Build|Construct).*(Scope|ScopeInfo|ScopeChain|ClassScope|DeclarationScope|ScopeAllocator)$")
    or this.getTarget().getQualifiedName().regexpMatch("(?i).*::(New|Create|Make|Allocate|Build|Construct).*(Scope|ScopeInfo|ScopeChain|ClassScope|DeclarationScope|ScopeAllocator)$")
  }
}

class NewScopeAllocExpr extends Expr {
  NewScopeAllocExpr() {
    this.toString().regexpMatch("(?i)\\bnew\\s+\\w*(Scope|ScopeInfo|ScopeChain|ClassScope|DeclarationScope)\\b")
  }
}

class FixupCall extends Call {
  FixupCall() {
    this.getTarget().getName().regexpMatch("(?i)(Finalize|FinalizeReparsed|Fixup|Apply|Patch|Restore|Reapply).*(Scope|ScopeInfo|Allocation|Reparsed|Reindex|Deserialize|Fixup)$")
    or this.getTarget().getQualifiedName().regexpMatch("(?i).*::(Finalize|FinalizeReparsed|Fixup|Apply|Patch|Restore|Reapply).*(Scope|ScopeInfo|Allocation|Reparsed|Reindex|Deserialize|Fixup)$")
  }
}

predicate hasVariablePointerInFile(File file) {
  exists(Field f |
    f.getDeclaringType().getFile() = file and
    f.getType().toString().regexpMatch("(?i)(^|[^A-Za-z0-9_])(Variable|VariableProxy)(::[A-Za-z0-9_]+)?\\s*\\*"))
}

from Function fun
where
  (
    exists(NewScopeCall n | n.getEnclosingFunction() = fun) or
    exists(NewScopeAllocExpr ne | ne.getEnclosingFunction() = fun)
  ) and
  exists(FixupCall x | x.getEnclosingFunction() = fun) and
  hasVariablePointerInFile(fun.getFile())
select
  fun,
  "Same function contains scope-creation-like call/alloc and scope-fixup-like call; file also holds Variable*/VariableProxy* fields. Triage required.",
  fun.getLocation()
