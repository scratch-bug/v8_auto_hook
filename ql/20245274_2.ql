import cpp

class RecordThisUseCall extends FunctionCall {
  RecordThisUseCall() {
    exists(Function target |
      target = this.getTarget() and
      target.getName() = "RecordThisUse"
    )
  }
}

from Function f, RecordThisUseCall call
where
  call.getEnclosingFunction() = f and
  (
    f.getName().regexpMatch("(?i).*Parse.*") or
    exists(File fi | fi = f.getFile() and fi.getRelativePath().regexpMatch("(?i).*(/parsing/|parser).*"))
  )
  // 이 함수 전체에서 FunctionParsingScope 지역이 전혀 없음
  and not exists(LocalVariable fps |
    fps.getFunction() = f and
    fps.getType().getUnspecifiedType().getName() = "FunctionParsingScope"
  )
select call, "RecordThisUse() on a path with no FunctionParsingScope in the enclosing function.", call.getLocation()
