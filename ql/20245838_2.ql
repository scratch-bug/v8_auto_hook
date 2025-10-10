import cpp

// 브랜치(then/else) 안에서 Wasm↔JS wrapper/연관 토큰이 언급되는지
private predicate branchMentionsWrapper(Stmt s) {
  s.toString().regexpMatch(
    "(?s)"
    // Wrapper 계열
    + "\\b(WasmToJSWrapper|WasmToJSWrapperAsm|WasmReturnPromiseOnSuspend|"
    + "WasmReturnPromiseOnSuspendAsm|WasmPromising|WasmPromisingWithSuspender|"
    + "JSToWasmWrapper|kWasmToJSWrapper)\\b"
    // Import 참조/캐스팅/디스패치 테이블
    + "|\\b(NewWasmApiFunctionRef|WasmApiFunctionRef::cast)\\b"
    + "|dispatch_table_for_imports\\s*\\(\\)\\s*\\->\\s*ref"
    // call target 설정 흔적
    + "|\\bset_call_target\\b"
  )
}

// if 문의 then/else 어느 한쪽이라도 wrapper 토큰이 있으면 true
private predicate hasWrapperMentionInBranch(IfStmt ifs) {
  exists(Stmt t | t = ifs.getThen() and branchMentionsWrapper(t))
  or
  exists(Stmt e | e = ifs.getElse() and branchMentionsWrapper(e))
}

// if 조건식에 imported 가드(function.imported / !function.imported / IsImported / is_imported / imported(...))가 있는지
private predicate conditionHasImportedGuard(IfStmt ifs) {
  exists(Expr cond |
    cond = ifs.getCondition() and
    cond.toString().regexpMatch(
      "function\\s*\\.\\s*imported"        // function.imported
      + "|!\\s*function\\s*\\.\\s*imported"// !function.imported
      + "|\\bIsImported\\b"                // IsImported
      + "|\\bis_imported\\b"               // is_imported
      + "|\\bimported\\s*\\("              // imported(...)
    )
  )
}

// 메인: 브랜치에 wrapper 관련 토큰이 있는데 조건식에 imported 가드가 없을 때만 잡기
from IfStmt ifs
where
  hasWrapperMentionInBranch(ifs) and
  not conditionHasImportedGuard(ifs)
select
  ifs,
  ifs.getLocation(),
  "Branch mentions Wasm/JS wrapper or import-ref, but the if-condition lacks an 'imported' guard."
