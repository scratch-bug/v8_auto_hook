import cpp

predicate isSpecialAccessFactoryCall(Expr e) {
  exists(FunctionCall fc |
    fc = e and
    (
      fc.getTarget().getName().regexpMatch("(^|.*::)ModuleExport$") or
      fc.getTarget().getName().regexpMatch("(^|.*::)PropertyAccessInfo::ModuleExport$") or
      fc.getTarget().getQualifiedName().regexpMatch(".*PropertyAccessInfo.*ModuleExport.*")
    )
  )
  or
  e.toString().regexpMatch("\\bkModuleExport\\b")
  or
  e.toString().regexpMatch("\\bPropertyAccessInfo\\s*::\\s*(FastAccessorConstant|FastDataConstant|ModuleExport|Invalid)\\b")
}

predicate isGuardCall(FunctionCall fc) {
  exists(Function cal |
    fc.getTarget() = cal and
    cal.getName().regexpMatch("(^|.*::)(IsAnyStore|IsTheHole|IsTheHoleValue|IsTheHoleOrUndefined|IsInObject|is_inobject|IsDataField|IsDictionaryMode|IsFieldRepresentation|IsSmi|IsDouble)$")
  )
  or
  fc.toString().regexpMatch("\\bIsAnyStore\\s*\\(") or
  fc.toString().regexpMatch("\\bIsTheHole\\s*\\(") or
  fc.toString().regexpMatch("\\bis_inobject\\s*\\(") or
  fc.toString().regexpMatch("\\bfield_representation\\b") or
  fc.toString().regexpMatch("\\bfield_index\\b") or
  fc.toString().regexpMatch("\\bIsDataField\\s*\\(")
}

predicate functionLacksGuards(Function f) {
  not exists(FunctionCall gc |
    gc.getEnclosingFunction() = f and
    isGuardCall(gc)
  )
}

from Function f, Expr e
where
  e.getEnclosingFunction() = f and
  isSpecialAccessFactoryCall(e) and
  functionLacksGuards(f)
select
  f, e,
  e.getLocation(),
  "This function creates/returns a special PropertyAccessInfo (module/export or similar) but the function contains no store/initialization/representation guard calls (IsAnyStore/IsTheHole/is_inobject/field_representation checks). Review for unsafe Store lowering."
