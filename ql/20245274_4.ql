import cpp

/**
 * parser_->expression_scope_ 를 "직접" 건드리는 모든 코드 패턴을 하나의 쿼리로 수집한다.
 * - A: 대입/복합대입/증감 (Stmt 문자열 기반 정규식)
 * - B: 함수 인자로 전달(간접 수정 가능성; Expr 문자열 기반 정규식)
 *
 * 결과 컬럼:
 *   e    : 적발된 코드 위치(Element)
 *   loc  : e의 소스 위치
 *   kind : "direct-write" | "arg-pass"
 */

from Element e, string kind
where
  // A) 직접 대입/복합대입/증감
  (
    exists(Stmt s |
      e = s and
      s.toString().regexpMatch(
        "(?s)"
        + "(?:\\+\\+\\s*(?:this->)?parser_\\s*(?:->|\\.)\\s*expression_scope_\\b"
        + "|--\\s*(?:this->)?parser_\\s*(?:->|\\.)\\s*expression_scope_\\b"
        + "|(?:this->)?parser_\\s*(?:->|\\.)\\s*expression_scope_\\b\\s*"
        + "(?:=|\\+=|-=|\\*=|/=|&=|\\|=|\\^=|<<=|>>=))"
      )
      and kind = "direct-write"
    )
  )
  or
  // B) 인자 전달(간접 수정 가능성)
  (
    exists(FunctionCall c, Expr arg |
      e = c and
      arg = c.getAnArgument() and
      arg.toString().regexpMatch(
        "(^|[^A-Za-z0-9_])(?:&\\s*)?(?:this->)?parser_\\s*(?:->|\\.)\\s*expression_scope_\\b"
      )
      and kind = "arg-pass"
    )
  )
select e, e.getLocation(), kind
