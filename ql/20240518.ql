import cpp

predicate isSetBytecode(Call c) {
  c.getTarget().getName().regexpMatch("(?i)set_bytecode_array")
  or c.toString().regexpMatch("(?i)\\bset_bytecode_array\\s*\\(")
}

predicate isSetFeedback(Call c) {
  c.getTarget().getName().regexpMatch("(?i)set_feedback_metadata")
  or c.toString().regexpMatch("(?i)\\bset_feedback_metadata\\s*\\(")
}

from Function f, Call setB
where
  setB.getEnclosingFunction() = f and
  isSetBytecode(setB) and
  not exists(Call setF |
    setF.getEnclosingFunction() = f and isSetFeedback(setF)
  )
select
  setB,
  f,
  setB.getLocation(),
  "Calls set_bytecode_array(...) but no set_feedback_metadata(...) in the same function."
                                                                                                                                                                                                                                                                                    