import cpp

predicate hasFastClone(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    (c.getTarget().getName().matches("%FastCloneJSObject%") or
     c.toString().regexpMatch("FastCloneJSObject\\s*\\("))
  )
}

predicate hasLoadProperties(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    (c.getTarget().getName().matches("%LoadJSReceiverPropertiesOrHash%") or
     c.toString().regexpMatch("LoadJSReceiverPropertiesOrHash\\s*\\("))
  )
}

predicate hasTaggedIsSmiCheck(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    (c.getTarget().getName().matches("%TaggedIsSmi%") or
     c.toString().regexpMatch("TaggedIsSmi\\s*\\("))
  )
}

from Function f
where hasFastClone(f) and not (hasLoadProperties(f) and hasTaggedIsSmiCheck(f))
select
  f,
  "Contains FastCloneJSObject and LoadJSReceiverPropertiesOrHash but no TaggedIsSmi call found in this function",
  f.getLocation()
