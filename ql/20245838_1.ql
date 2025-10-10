import cpp

class ImportJSWrapperMentionedFunction extends Function {
  ImportJSWrapperMentionedFunction() {
    exists(Stmt s |
      s.getEnclosingFunction() = this and
      s.toString().regexpMatch(
        "(?s)"
        + "\\b(Builtins::)?kWasmToJSWrapper\\b"
        + "|\\bWasmToJSWrapper(Asm|CSA)?\\b"
        + "|\\bWasmPromising(WithSuspender)?\\b"
        + "|\\bWasmReturnPromiseOnSuspend(Asm)?\\b"
        + "|\\bNewWasmApiFunctionRef\\b"
        + "|\\bWasmApiFunctionRef::cast\\b"
        + "|dispatch_table_for_imports\\s*\\(\\)\\s*->\\s*ref"
        + "|\\bWasmImportedFunction\\b"
        + "|\\bWasmImportData\\b"
        + "|\\bWasmImport[A-Za-z0-9_]*Wrapper\\b"
        + "|code_handle\\s*\\(\\s*(Builtins::)?kWasmToJSWrapper\\s*\\)"
      )
    )
    or
    exists(Call c, Function cal |
      c.getEnclosingFunction() = this and
      c.getTarget() = cal and
      (
        cal.getName().regexpMatch(
          "^(WasmToJSWrapper|WasmToJSWrapperAsm|WasmPromising(WithSuspender)?|WasmReturnPromiseOnSuspend(Asm)?|NewWasmApiFunctionRef|WasmApiFunctionRef.*)$"
        )
        or
        cal.getQualifiedName().regexpMatch(
          "(^|.*::)(WasmToJSWrapper|WasmToJSWrapperAsm|Generate_WasmToJSWrapper|BuildWasmToJSWrapper|WasmPromising(WithSuspender)?|WasmReturnPromiseOnSuspend(Asm)?|NewWasmApiFunctionRef|WasmApiFunctionRef.*)($|::)"
        )
      )
    )
  }
}

from ImportJSWrapperMentionedFunction f
select
  f,
  "Mentions Wasm-import-call wrappers/related APIs. File: "
  + f.getFile().getRelativePath() + " ; function: " + f.getName(),
  f.getLocation()
