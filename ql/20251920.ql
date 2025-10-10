import cpp

from Function fn, Stmt allocStmt
where
  allocStmt.getEnclosingFunction() = fn and
  allocStmt.toString().regexpMatch("BuildAllocateFastObject\\s*\\(") and
  not exists(Stmt clearStmt |
    clearStmt.getEnclosingFunction() = fn and
    clearStmt.toString().regexpMatch("ClearCurrentRawAllocation\\s*\\(") and
    clearStmt.getLocation().getStartLine() > allocStmt.getLocation().getStartLine()
  )
select
  allocStmt,
  allocStmt.getLocation(),
  "Candidate: 이 위치 이후 함수 내에 ClearCurrentRawAllocation 호출이 없습니다."
