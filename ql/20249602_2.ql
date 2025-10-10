/**
 * Find functions that use wasm_max_module_size / max_module_size (heuristic)
 * but do NOT contain an obvious clamp() or kV8MaxWasmModuleSize reference
 * inside the same function.
 *
 * - Uses `exists(...)` for safe binding instead of comparing to `null`.
 * - Restricts file paths to wasm/stream/decoder-like paths to reduce noise.
 * - Looks for call targets by name when available, otherwise falls back to a small toString() check.
 */

import cpp

from Function f, Call useCall
where
  // 2) find a call inside the function that likely uses the flag / max helper
  useCall.getEnclosingFunction() = f
  and (
    // preferred: resolved target function named max_module_size
    exists(Function callee | useCall.getTarget() = callee and callee.getName().regexpMatch("(?i)max_module_size"))
    // fallback: textual occurrence of v8_flags::wasm_max_module_size or wasm_max_module_size(...)
    or useCall.toString().regexpMatch("(?i)\\bv8_flags\\s*(:{2}|\\.)\\s*wasm_max_module_size\\b|wasm_max_module_size\\s*\\(")
  )

  // 3) ensure there's no obvious clamp() call in the same function
  and not exists(Call clampCall |
    clampCall.getEnclosingFunction() = f
    and exists(Function clampTarget |
      clampCall.getTarget() = clampTarget
      and clampTarget.getName().regexpMatch("(?i)(std::clamp|clamp)")
    )
  )

  // 4) and no obvious reference to the engine max constant in the same function
  and not exists(Expr constRef |
    constRef.getEnclosingFunction() = f
    and constRef.toString().regexpMatch("(?i)\\bkV8MaxWasmModuleSize\\b|\\bK_V8_MAX_WASM_MODULE_SIZE\\b")
  )

select
  f,
  useCall,
  "Uses wasm_max_module_size/max_module_size in a wasm/streaming-related file but contains no obvious clamp() or kV8MaxWasmModuleSize check in the same function (heuristic). Review whether the flag value is clamped before use.",
  useCall.getLocation()
