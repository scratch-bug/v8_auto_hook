import cpp

predicate inLikelyWasmFile(Function f) {
  exists(File fi |
    fi = f.getFile() and
    fi.getRelativePath().regexpMatch(
      "(?i).*(/|\\\\)src(/|\\\\).*(wasm|wasm-to-js|wasm-gen|builtins|wasm_js|wasm_).*"
    )
  )
}

predicate isWasmParamRead(Call c) {
  exists(Function t | t = c.getTarget() and t.getName().regexpMatch("(?i)^(UncheckedParameter|UncheckedWasmParam|ReadWasmParam|GetWasmParam|ReadValueFromStack)$"))
}

predicate isJsFieldOrObjectUse(Call c) {
  exists(Function t | t = c.getTarget() and t.getName().regexpMatch("(?i)(LoadObjectField|StoreObjectField|LoadFixedArray|ToObject|TaggedToObject|CallRuntime|JSObject|JSReceiver|LoadFastElement|GetProperty|SetProperty|SetObjectField|GetObjectField)"))
}

predicate isValidationOrThrow(Call c) {
  exists(Function t | t = c.getTarget() and t.getName().regexpMatch("(?i)(WasmThrowJSTypeError|WasmToJsWrapperInvalidSig|ThrowJSTypeError|ThrowTypeError|InvalidSig)"))
}

predicate hasValueKindMaskCheck(Function f) {
  exists(Stmt s | s.getEnclosingFunction() = f and s.toString().regexpMatch(".*kValueTypeKindBitsMask.*"))
}

from Function func
where
  inLikelyWasmFile(func) and
  exists(Call readCall, Call useCall |
    readCall.getEnclosingFunction() = func and isWasmParamRead(readCall) and
    useCall.getEnclosingFunction() = func and isJsFieldOrObjectUse(useCall) and
    readCall.getLocation().getStartLine() < useCall.getLocation().getStartLine()
  ) and
  not exists(Call guard | guard.getEnclosingFunction() = func and isValidationOrThrow(guard)) and
  not hasValueKindMaskCheck(func)
select
  func,
  "Candidate function (one row per function) — inspect for wasm->js conversion without value-kind validation.",
  func.getLocation()
