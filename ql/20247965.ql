import cpp

predicate hasDirectRecursion(Function f) {
  exists(Call c | c.getEnclosingFunction() = f and c.getTarget() = f)
}

predicate mentionsGuardLike(Function f) {
  exists(Expr e |
    e.getEnclosingFunction() = f and
    e.toString().regexpMatch("(?i)(recursion[_]?depth|\\bdepth\\b|visit(?:ed|ing)?|guard|seen|stack|on[_]?stack|in[_]?progress|checking|grey|gray|black|white)")
  )
}

predicate writesStateLikeByAssign(Function f) {
  exists(AssignExpr a |
    a.getEnclosingFunction() = f and
    a.getLValue().toString().regexpMatch(
      "(?is).*\\b(?:this->)?(?:" +
      "phi[_]?(?:state|states)|phistates?|phi_state|phiVisited|" +
      "upper(?:32|64)?bits?|upper[_]?bits|upperBits|" +
      "zero(?:extend|extends|ext|zext)?|zero[_]?extend|zero[_]?bits?|zero[_]?upper|" +
      "visited|visiting|visit|" +
      "mark(?:ed|ing)?|" +
      "seen|" +
      "color(?:s)?|colour(?:s)?|grey|gray|black|white|" +
      "flag(?:s)?|" +
      "status|state(?:s)?|stage(?:s)?|phase(?:s)?|level(?:s)?|" +
      "lattice|top|bottom|meet|join|changed|work|" +
      "worklist|queue|deque|pending|" +
      "stack|on[_]?stack|in[_]?stack|callstack|" +
      "in[_]?progress|progress|processing|" +
      "checking|checked|validated|verified|" +
      "processed|done|finalized|" +
      "seenmap|visitmap|markmap|statemap|" +
      "phi[_]?states?vec|states?vec|markvec|visitvec|colorvec|" +
      "phi[_]?states?arr|states?arr|markarr|visitarr|colorarr|" +
      "bitmap|bitset|bits|mask|" +
      "upper32zero|upper64zero|zeroUpperBits" +
      ")\\b(?:\\s*\\[.*\\])?.*"
    )
  )
}

predicate writesStateLikeByCall(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    c.toString().regexpMatch(
      "(?is).*\\b(?:this->)?(?:" +
      "phi[_]?(?:state|states)|phistates?|phi_state|phiVisited|" +
      "upper(?:32|64)?bits?|upper[_]?bits|upperBits|" +
      "zero(?:extend|extends|ext|zext)?|zero[_]?extend|zero[_]?bits?|zero[_]?upper|" +
      "visited|visiting|visit|" +
      "mark(?:ed|ing)?|" +
      "seen|" +
      "color(?:s)?|colour(?:s)?|grey|gray|black|white|" +
      "flag(?:s)?|" +
      "status|state(?:s)?|stage(?:s)?|phase(?:s)?|level(?:s)?|" +
      "lattice|top|bottom|meet|join|changed|work|" +
      "worklist|queue|deque|pending|" +
      "stack|on[_]?stack|in[_]?stack|callstack|" +
      "in[_]?progress|progress|processing|" +
      "checking|checked|validated|verified|" +
      "processed|done|finalized|" +
      "seenmap|visitmap|markmap|statemap|" +
      "phi[_]?states?vec|states?vec|markvec|visitvec|colorvec|" +
      "phi[_]?states?arr|states?arr|markarr|visitarr|colorarr|" +
      "bitmap|bitset|bits|mask|" +
      "upper32zero|upper64zero|zeroUpperBits" +
      ")\\b.*\\.(?:" +
      "assign|set|clear|reset|init|initialize|reinit|fill(?:_n)?|" +
      "resize|reserve|shrink_to_fit|swap|erase|insert|" +
      "push_back|emplace(?:_back)?|write|store|update|mark|visit" +
      ")\\s*\\("
    )
  )
}

predicate callsResetMemset(Function f) {
  exists(FunctionCall fc |
    fc.getEnclosingFunction() = f and
    fc.getTarget().getName().regexpMatch("(?i)(memset|bzero|memset_s)")
  )
}

predicate callsResetByAlgo(Function f) {
  exists(FunctionCall fc |
    fc.getEnclosingFunction() = f and
    fc.getTarget().getName().regexpMatch("(?i)(fill|fill_n|std::fill|std::fill_n)")
  )
}

predicate callsResetOnMember(Function f) {
  exists(Call c |
    c.getEnclosingFunction() = f and
    c.toString().regexpMatch("(?is).*\\.(?:clear|assign|resize|fill(?:_n)?|reset|release|shrink_to_fit|erase|swap)\\s*\\(")
  )
}

from Function f
where hasDirectRecursion(f)
  and (writesStateLikeByAssign(f) or writesStateLikeByCall(f))
  and not callsResetMemset(f)
  and not callsResetByAlgo(f)
  and not callsResetOnMember(f)
  and not mentionsGuardLike(f)
select f, "Recursive function writes to state-like member without clear/guard at entry (broad names, text-heuristic).", f.getLocation()
