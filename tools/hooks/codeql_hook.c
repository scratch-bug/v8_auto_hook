#ifndef CODEQL_HOOK_C
#define CODEQL_HOOK_C

#include "tools/hooks/codeql_hook.h"

#include <unistd.h>
#include <string.h>
#include <stdint.h>

/* --- Atomic toggle flag (default: OFF) ----------------------------------- */
#if defined(__STDC_NO_ATOMICS__) || (__STDC_VERSION__ < 201112L)
  /* Fallback when C11 atomics are unavailable in build config */
  static volatile int g_custom_hook_enabled = 0;
  #define HOOK_ATOMIC_STORE(val) (g_custom_hook_enabled = (val))
  #define HOOK_ATOMIC_LOAD()     (g_custom_hook_enabled)
#else
  #include <stdatomic.h>
  static _Atomic int g_custom_hook_enabled = 0;
  #define HOOK_ATOMIC_STORE(val) atomic_store_explicit(&g_custom_hook_enabled, (val), memory_order_release)
  #define HOOK_ATOMIC_LOAD()     atomic_load_explicit(&g_custom_hook_enabled, memory_order_acquire)
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Toggle: 0 = off, nonzero = on */
__attribute__((noinline)) __attribute__((used))
void CustomHook_SetEnabled(int on) {
  HOOK_ATOMIC_STORE(on ? 1 : 0);
}

__attribute__((noinline)) __attribute__((used))
int CustomHook_IsEnabled(void) {
  return HOOK_ATOMIC_LOAD();
}

/* Raw emitter: ALWAYS writes one line to stderr (ignores toggle).
   Header’s CustomPoint_HOOK macro calls this only when enabled == 1. */
__attribute__((noinline)) __attribute__((used))
void CustomPoint_HOOK_emit(const char* tag) {
  static const char prefix[] = "[HOOK1] CUSTOM_V8_HIT";
  static const char sep[]    = " : ";
  static const char nl[]     = "\n";

  /* prefix */
  (void)write(2, prefix, sizeof(prefix) - 1);

  /* optional " : <tag>" */
  if (tag && tag[0] != '\0') {
    (void)write(2, sep, sizeof(sep) - 1);
    (void)write(2, tag, (size_t)strlen(tag));
  }

  /* newline */
  (void)write(2, nl, sizeof(nl) - 1);
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* CODEQL_HOOK_C */
