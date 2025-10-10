import cpp

from Function fn, Stmt s1, Stmt s2
where
  s1.getEnclosingFunction() = fn and
  s2.getEnclosingFunction() = fn and
  s1.getLocation().getStartLine() < s2.getLocation().getStartLine() and
  s1.toString().regexpMatch("BuildAllocateFastObject\\s*\\(") and
  s2.toString().regexpMatch("BuildAllocateFastObject\\s*\\(") and
  not exists(Stmt sc |
    sc.getEnclosingFunction() = fn and
    sc.toString().regexpMatch("ClearCurrentRawAllocation\\s*\\(") and
    sc.getLocation().getStartLine() > s1.getLocation().getStartLine() and
    sc.getLocation().getStartLine() < s2.getLocation().getStartLine()
  )
select
  s2, s2.getLocation(),
  "Candidate: 두 BuildAllocateFastObject 호출 사이에 ClearCurrentRawAllocation이 보이지 않습니다. (문제가 드러나는 호출 위치: 두번째 호출)"
